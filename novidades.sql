-- Novidades: só a ETAPA 25 (condomínio, imobiliária, aluguel, casas 50% mais caras). As etapas 21 a 24 já foram rodadas.

-- ===================== ETAPA 25: Condomínio Vila Tonhão (apartamentos para comprar ou alugar) e casas 50% mais caras =====================
-- Os apartamentos ficam na mesma tabela das casas (id 1101 a 1444): assim móveis, geladeira e porta funcionam igual.
-- Número: 1000 + bloco×100 + andar×10 + final. Blocos A, B e C = kitnet; bloco D = 2 quartos.
create table if not exists public.migracoes (id text primary key, feita_em timestamptz not null default now());
alter table public.casas add column if not exists alugada boolean not null default false;
alter table public.casas add column if not exists aluguel_ate timestamptz;
alter table public.casas add column if not exists valor_aluguel integer;

-- o "tipo" passa a considerar apartamento e os preços novos (casas 50% mais caras)
drop index if exists public.casas_um_por_tipo;
alter table public.casas drop column if exists tipo;
alter table public.casas add column tipo text generated always as (case when id > 1000 then 'apto' when preco >= 75000 then 'mansao' when preco >= 15000 then 'media' else 'barata' end) stored;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;

-- casas da cidade 50% mais caras (roda uma vez só)
do $$ begin
  if not exists (select 1 from public.migracoes where id = 'casas_x15') then
    update public.casas set preco = round(preco * 1.5) where id < 1000;
    insert into public.migracoes(id) values ('casas_x15');
  end if;
end $$;

-- os 64 apartamentos
insert into public.casas(id, preco, nivel_min, valor_aluguel)
select 1000 + b * 100 + a * 10 + f, case when b <= 3 then 4000 else 6000 end, 1, case when b <= 3 then 250 else 350 end
from generate_series(1, 4) b, generate_series(1, 4) a, generate_series(1, 4) f
on conflict (id) do update set preco = excluded.preco, valor_aluguel = excluded.valor_aluguel;

-- vende os móveis pela metade e deixa o apartamento vago
create or replace function public._vagar_apto(p_casa integer) returns integer
language plpgsql security definer set search_path = public as $$
declare c public.casas; volta integer := 0;
begin
  select * into c from casas where id = p_casa and id > 1000 for update;
  if c.id is null or c.dono is null then return 0; end if;
  select coalesce(sum(coalesce(preco_movel(e->>'t'), 0) / 2), 0) into volta from jsonb_array_elements(c.moveis) e;
  update moradores set dinheiro = dinheiro + volta, casa_id = case when casa_id = c.id then null else casa_id end where id = c.dono;
  update casas set dono = null, comprada_em = null, aberta = false, alugada = false, aluguel_ate = null, moveis = '[]'::jsonb, geladeira = '{}'::jsonb where id = c.id;
  return volta;
end $$;
revoke execute on function public._vagar_apto(integer) from public, anon, authenticated;

-- apartamento alugado e vencido há mais de 3 dias volta a ficar livre
create or replace function public._limpa_aptos() returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from casas where id > 1000 and alugada and aluguel_ate < now() - interval '3 days' loop
    perform _vagar_apto(r.id);
  end loop;
end $$;
revoke execute on function public._limpa_aptos() from public, anon, authenticated;

create or replace function public._pegar_apto(p_casa integer, p_alugar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antigo integer; volta integer := 0; custo integer;
begin
  m := _eu();
  perform _limpa_aptos();
  select * into c from casas where id = p_casa and id > 1000 for update;
  if not found then raise exception 'Esse apartamento não existe.'; end if;
  if c.dono = m.id then raise exception 'Esse apartamento já é seu.'; end if;
  if c.dono is not null then raise exception 'Esse apartamento já tem morador.'; end if;
  if exists (select 1 from casas where dono = m.id and id < 1000) then raise exception 'Quem tem casa na cidade não pode ter apartamento.'; end if;
  custo := case when p_alugar then c.valor_aluguel else c.preco end;
  select id into antigo from casas where dono = m.id and id > 1000;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  if antigo is not null then volta := _vagar_apto(antigo); end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false, alugada = p_alugar,
    aluguel_ate = case when p_alugar then now() + interval '7 days' else null end where id = c.id;
  update moradores set dinheiro = dinheiro - custo, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;
revoke execute on function public._pegar_apto(integer, boolean) from public, anon, authenticated;

create or replace function public.comprar_apto(p_casa integer) returns json
language sql security definer set search_path = public as $$ select _pegar_apto(p_casa, false) $$;
create or replace function public.alugar_apto(p_casa integer) returns json
language sql security definer set search_path = public as $$ select _pegar_apto(p_casa, true) $$;
grant execute on function public.comprar_apto(integer) to authenticated;
grant execute on function public.alugar_apto(integer) to authenticated;

create or replace function public.sair_apto() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c integer; volta integer := 0;
begin
  m := _eu();
  select id into c from casas where dono = m.id and id > 1000;
  if c is null then raise exception 'Você não mora no condomínio.'; end if;
  volta := _vagar_apto(c);
  return json_build_object('devolvido', volta, 'eu', _estado(m.id));
end $$;
grant execute on function public.sair_apto() to authenticated;

-- cobra o aluguel vencido (o jogo chama ao entrar e a cada 10 minutos)
create or replace function public.cobrar_aluguel() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pago integer := 0;
begin
  m := _eu();
  select * into c from casas where dono = m.id and id > 1000 and alugada for update;
  if c.id is null then return json_build_object('ok', true); end if;
  while c.aluguel_ate <= now() and m.dinheiro >= c.valor_aluguel loop
    m.dinheiro := m.dinheiro - c.valor_aluguel; pago := pago + c.valor_aluguel; c.aluguel_ate := c.aluguel_ate + interval '7 days';
  end loop;
  update moradores set dinheiro = m.dinheiro where id = m.id;
  update casas set aluguel_ate = c.aluguel_ate where id = c.id;
  if c.aluguel_ate < now() - interval '3 days' then
    perform _vagar_apto(c.id);
    return json_build_object('despejado', true, 'pago', pago, 'eu', _estado(m.id));
  end if;
  return json_build_object('pago', pago, 'atrasado', c.aluguel_ate < now(), 'valor', c.valor_aluguel, 'eu', _estado(m.id));
end $$;
grant execute on function public.cobrar_aluguel() to authenticated;

-- comprar casa na cidade deixa o apartamento vago (o jogo avisa antes)
create or replace function public.comprar_casa(p_casa integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antiga public.casas; volta integer := 0; apto integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and id < 1000 for update;
  if not found then raise exception 'Essa casa não existe.'; end if;
  if c.dono = m.id then raise exception 'Essa casa já é sua.'; end if;
  if c.dono is not null then raise exception 'Essa casa já tem dono.'; end if;
  if m.nivel < c.nivel_min then raise exception 'Essa casa libera no nível %.', c.nivel_min; end if;
  select * into antiga from casas where dono = m.id and tipo = c.tipo for update;
  if found then volta := antiga.preco / 2; end if;
  if m.dinheiro + volta < c.preco then raise exception 'Dinheiro insuficiente para essa casa.'; end if;
  if antiga.id is not null then
    update casas set dono = null, comprada_em = null, aberta = false where id = antiga.id;
    update vagas set morador = null, carro = null, desde = null where casa = antiga.id;
  end if;
  select id into apto from casas where dono = m.id and id > 1000;
  if apto is not null then volta := volta + _vagar_apto(apto); end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false where id = c.id;
  update moradores set dinheiro = dinheiro + volta - c.preco, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;
