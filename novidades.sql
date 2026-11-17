-- Novidades: só a ETAPA 28 (Passe da Temporada e VIP turbinado). As etapas 21 a 27 já foram rodadas.

-- ===================== ETAPA 28: Passe da Temporada e VIP turbinado =====================
-- Passe: 20 níveis (100 pontos cada). Tarefa de emprego = 10 pontos, pagamento da patrulha = 15, VIP ganha +50%.
-- Trilha grátis para todos; trilha premium comprada no Pix (produto passe_T1). Prêmios só visuais ou dinheiro do jogo.
alter table public.produtos drop constraint if exists produtos_tipo_check;
alter table public.produtos add constraint produtos_tipo_check check (tipo in ('vip','pet','carro','passe'));
insert into public.produtos(id, tipo, item, dias, nome, preco) values
  ('vip90', 'vip', null, 90, 'VIP 90 dias', 39.90),
  ('passe_T1', 'passe', 'T1', 0, 'Passe Natal na Vila', 9.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, dias = excluded.dias, nome = excluded.nome, preco = excluded.preco;

create table if not exists public.passe_temporadas (
  id text primary key, nome text not null, inicio timestamptz not null, fim timestamptz not null
);
alter table public.passe_temporadas add column if not exists carro_pronto boolean not null default false; -- o carro exclusivo só pode ser resgatado quando estiver no jogo
insert into public.passe_temporadas(id, nome, inicio, fim) values ('T1', 'Natal na Vila', '2026-11-17 00:00-03', '2027-01-01 00:00-03')
on conflict (id) do update set nome = excluded.nome, inicio = excluded.inicio, fim = excluded.fim;

create table if not exists public.passe_premios (
  temporada text not null references public.passe_temporadas(id) on delete cascade,
  nivel integer not null check (nivel between 1 and 20),
  trilha text not null check (trilha in ('gratis','premium')),
  premio jsonb not null,   -- {"dinheiro":500} | {"estampa":11} | {"roupa":[item_homem,item_mulher]} (também calca, calcado, chapeu, extra)
  primary key (temporada, nivel, trilha)
);
insert into public.passe_premios(temporada, nivel, trilha, premio) values
  ('T1',1,'gratis','{"dinheiro": 300}'),
  ('T1',1,'premium','{"chapeu": [31, 31]}'),
  ('T1',2,'gratis','{"dinheiro": 300}'),
  ('T1',2,'premium','{"roupa": [22, 17]}'),
  ('T1',3,'gratis','{"dinheiro": 400}'),
  ('T1',3,'premium','{"chapeu": [6, 8]}'),
  ('T1',4,'gratis','{"estampa": 5}'),
  ('T1',4,'premium','{"dinheiro": 3000}'),
  ('T1',5,'gratis','{"chapeu": [30, 30]}'),
  ('T1',5,'premium','{"calca": [15, 22]}'),
  ('T1',6,'gratis','{"dinheiro": 500}'),
  ('T1',6,'premium','{"roupa": [20, 16]}'),
  ('T1',7,'gratis','{"dinheiro": 600}'),
  ('T1',7,'premium','{"calcado": [7, 3]}'),
  ('T1',8,'gratis','{"chapeu": [3, 3]}'),
  ('T1',8,'premium','{"dinheiro": 3000}'),
  ('T1',9,'gratis','{"dinheiro": 700}'),
  ('T1',9,'premium','{"roupa": [19, 15]}'),
  ('T1',10,'gratis','{"dinheiro": 800}'),
  ('T1',10,'premium','{"dinheiro": 10000}'),
  ('T1',11,'gratis','{"dinheiro": 800}'),
  ('T1',11,'premium','{"extra": [6, 5]}'),
  ('T1',12,'gratis','{"estampa": 7}'),
  ('T1',12,'premium','{"calca": [13, 23]}'),
  ('T1',13,'gratis','{"dinheiro": 900}'),
  ('T1',13,'premium','{"roupa": [21, 13]}'),
  ('T1',14,'gratis','{"dinheiro": 1000}'),
  ('T1',14,'premium','{"chapeu": [7, 7]}'),
  ('T1',15,'gratis','{"dinheiro": 1000}'),
  ('T1',15,'premium','{"dinheiro": 4000}'),
  ('T1',16,'gratis','{"roupa": [10, 10]}'),
  ('T1',16,'premium','{"calcado": [6, 7]}'),
  ('T1',17,'gratis','{"dinheiro": 1200}'),
  ('T1',17,'premium','{"roupa": [17, 14]}'),
  ('T1',18,'gratis','{"dinheiro": 1200}'),
  ('T1',18,'premium','{"extra": [7, 4]}'),
  ('T1',19,'gratis','{"dinheiro": 1500}'),
  ('T1',19,'premium','{"dinheiro": 6000}'),
  ('T1',20,'gratis','{"dinheiro": 2000}'),
  ('T1',20,'premium','{"carro": "natal"}')
on conflict (temporada, nivel, trilha) do update set premio = excluded.premio;

create table if not exists public.passe_jogador (
  morador uuid not null references public.moradores(id) on delete cascade,
  temporada text not null references public.passe_temporadas(id) on delete cascade,
  pontos integer not null default 0,
  premium boolean not null default false,
  resgatados text[] not null default '{}',   -- '5g' = nível 5 grátis, '5p' = nível 5 premium
  primary key (morador, temporada)
);
alter table public.passe_temporadas enable row level security;
alter table public.passe_premios enable row level security;
alter table public.passe_jogador enable row level security;
drop policy if exists "ler temporadas" on public.passe_temporadas;
create policy "ler temporadas" on public.passe_temporadas for select using (true);
drop policy if exists "ler premios" on public.passe_premios;
create policy "ler premios" on public.passe_premios for select using (true);
revoke insert, update, delete on public.passe_temporadas, public.passe_premios, public.passe_jogador from anon, authenticated;

create or replace function public._temporada_atual() returns text
language sql stable security definer set search_path = public as $$
  select id from passe_temporadas where now() >= inicio and now() < fim order by inicio desc limit 1
$$;

create or replace function public._passe_pontos(p_morador uuid, p_pontos integer) returns void
language plpgsql security definer set search_path = public as $$
declare t text := _temporada_atual(); vip boolean;
begin
  if t is null then return; end if;
  select coalesce(vip_ate > now(), false) into vip from moradores where id = p_morador;
  insert into passe_jogador(morador, temporada, pontos) values (p_morador, t, least(2000, case when vip then round(p_pontos * 1.5) else p_pontos end))
  on conflict (morador, temporada) do update set pontos = least(2000, passe_jogador.pontos + case when vip then round(p_pontos * 1.5) else p_pontos end);
end $$;
revoke execute on function public._passe_pontos(uuid, integer) from public, anon, authenticated;
revoke execute on function public._temporada_atual() from public, anon;

create or replace function public.meu_passe() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.passe_temporadas; j public.passe_jogador;
begin
  m := _eu();
  select * into t from passe_temporadas where id = _temporada_atual();
  if t.id is null then return json_build_object('temporada', null); end if;
  select * into j from passe_jogador where morador = m.id and temporada = t.id;
  return json_build_object('temporada', t.id, 'nome', t.nome, 'fim', t.fim, 'pontos', coalesce(j.pontos, 0),
    'premium', coalesce(j.premium, false), 'resgatados', coalesce(j.resgatados, '{}'),
    'premios', (select json_agg(json_build_object('nivel', nivel, 'trilha', trilha, 'premio', premio) order by nivel, trilha) from passe_premios where temporada = t.id));
end $$;
grant execute on function public.meu_passe() to authenticated;

-- entrega um prêmio visual (roupa para os dois sexos, estampa) ou dinheiro do jogo
create or replace function public._dar_premio(p_morador uuid, p jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare k text;
begin
  if p ? 'dinheiro' then update moradores set dinheiro = dinheiro + (p->>'dinheiro')::int where id = p_morador; end if;
  if p ? 'carro' then update moradores set carros = case when (p->>'carro') = any(carros) then carros else array_append(carros, p->>'carro') end where id = p_morador; end if;
  if p ? 'estampa' then insert into guarda_roupa(morador, peca, item) values (p_morador, 'estampa', (p->>'estampa')::int) on conflict do nothing; end if;
  foreach k in array array['roupa','calca','calcado','chapeu','extra'] loop
    if p ? k then
      insert into guarda_roupa(morador, peca, item) values (p_morador, k || '_m', (p->k->>0)::int), (p_morador, k || '_f', (p->k->>1)::int) on conflict do nothing;
    end if;
  end loop;
end $$;
revoke execute on function public._dar_premio(uuid, jsonb) from public, anon, authenticated;

create or replace function public.resgatar_passe(p_nivel integer, p_trilha text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := _temporada_atual(); j public.passe_jogador; pr jsonb; cod text;
begin
  m := _eu();
  if t is null then raise exception 'Nenhuma temporada ativa agora.'; end if;
  select * into j from passe_jogador where morador = m.id and temporada = t for update;
  if j.morador is null or j.pontos < p_nivel * 100 then raise exception 'Você ainda não chegou nesse nível do passe.'; end if;
  if p_trilha = 'premium' and not j.premium then raise exception 'Esse prêmio é do Passe Premium.'; end if;
  cod := p_nivel || case when p_trilha = 'premium' then 'p' else 'g' end;
  if cod = any(j.resgatados) then raise exception 'Você já pegou esse prêmio.'; end if;
  select premio into pr from passe_premios where temporada = t and nivel = p_nivel and trilha = p_trilha;
  if pr is null then raise exception 'Prêmio não encontrado.'; end if;
  if pr ? 'carro' and not (select carro_pronto from passe_temporadas where id = t) then raise exception 'O carro exclusivo chega em breve!'; end if;
  perform _dar_premio(m.id, pr);
  update passe_jogador set resgatados = array_append(resgatados, cod) where morador = m.id and temporada = t;
  return json_build_object('premio', pr, 'eu', _estado(m.id));
end $$;
grant execute on function public.resgatar_passe(integer, text) to authenticated;

-- presente do mês do VIP (só quem está VIP naquele mês pega; fica para sempre)
create table if not exists public.vip_mensal (mes text primary key, premio jsonb not null);
insert into public.vip_mensal(mes, premio) values
  ('2026-11', '{"roupa":[14,12]}'), ('2026-12', '{"calca":[11,13]}'), ('2027-01', '{"roupa":[18,11]}'),
  ('2027-02', '{"estampa":10}'), ('2027-03', '{"calcado":[5,6]}'), ('2027-04', '{"chapeu":[8,6]}')
on conflict (mes) do update set premio = excluded.premio;
create table if not exists public.vip_presentes (
  morador uuid not null references public.moradores(id) on delete cascade, mes text not null, pego_em timestamptz not null default now(),
  primary key (morador, mes)
);
alter table public.vip_mensal enable row level security;
alter table public.vip_presentes enable row level security;
drop policy if exists "ler vip mensal" on public.vip_mensal;
create policy "ler vip mensal" on public.vip_mensal for select using (true);
revoke insert, update, delete on public.vip_mensal, public.vip_presentes from anon, authenticated;

create or replace function public.presente_vip() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v_mes text := to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM'); pr jsonb;
begin
  m := _eu();
  if not coalesce(m.vip_ate > now(), false) then raise exception 'O presente do mês é só para quem é VIP.'; end if;
  select premio into pr from vip_mensal where vip_mensal.mes = v_mes;
  if pr is null then raise exception 'O presente deste mês ainda não chegou.'; end if;
  if exists (select 1 from vip_presentes where morador = m.id and vip_presentes.mes = v_mes) then raise exception 'Você já pegou o presente deste mês.'; end if;
  perform _dar_premio(m.id, pr);
  insert into vip_presentes(morador, mes) values (m.id, v_mes);
  return json_build_object('premio', pr, 'mes', v_mes, 'eu', _estado(m.id));
end $$;
grant execute on function public.presente_vip() to authenticated;

create or replace function public.vip_info() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v_mes text := to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM');
begin
  m := _eu();
  return json_build_object('mes', v_mes, 'premio', (select premio from vip_mensal where vip_mensal.mes = v_mes),
    'pego', exists (select 1 from vip_presentes where morador = m.id and vip_presentes.mes = v_mes));
end $$;
grant execute on function public.vip_info() to authenticated;

-- entrega: agora também o passe
create or replace function public._entregar(p_pedido uuid, p_mp_id text, p_valor numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare pd public.pedidos; pr public.produtos;
begin
  select * into pd from pedidos where id = p_pedido for update;
  if not found or pd.status = 'entregue' then return false; end if;
  if p_valor < pd.valor then raise exception 'Valor pago menor que o pedido.'; end if;
  select * into pr from produtos where id = pd.produto;
  if pr.tipo = 'vip' then
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => pr.dias) where id = pd.morador;
  elsif pr.tipo = 'pet' then
    update moradores set pets = case when pr.item = any(pets) then pets else array_append(pets, pr.item) end,
      pet = pr.item where id = pd.morador;
  elsif pr.tipo = 'carro' then
    update moradores set carros = case when pr.item = any(carros) then carros else array_append(carros, pr.item) end where id = pd.morador;
  elsif pr.tipo = 'passe' then
    insert into passe_jogador(morador, temporada, premium) values (pd.morador, pr.item, true)
    on conflict (morador, temporada) do update set premium = true;
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;
grant execute on function public._entregar(uuid, text, numeric) to service_role;

-- pontos do passe nas tarefas e na patrulha
create or replace function public.tarefa_feita() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; extra integer; pago integer; ganho integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '2.5 seconds' then
    raise exception 'Calma! Uma tarefa de cada vez.';
  end if;
  select * into t from trabalhos where id = m.trabalho;
  extra := greatest(0, m.nivel - t.nivel_min);
  pago  := round(t.salario / 6.0 * (1 + 0.06 * extra));
  ganho := greatest(1, round(t.xp / 5.0 * (1 + 0.04 * extra)));  -- XP por tarefa (era /6, /20, /10, /4)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, 10);
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;


create or replace function public.ronda_policia() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is distinct from 'policia' then raise exception 'Você não está de patrulha.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '85 seconds' then
    raise exception 'O próximo pagamento da patrulha ainda não chegou.';
  end if;
  novo_xp := m.xp + 20;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + 50 + premio, xp = novo_xp, nivel = novo_nivel, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, 15);
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 50, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;

-- itens exclusivos (30-39) não são vendidos na loja de roupas: só quem ganhou no passe
create or replace function public.preco_roupa(p_peca text, p_item integer) returns integer
language sql immutable as $$
  select case
    when p_item >= 40 then coalesce((case p_peca
      when 'chapeu_m' then array[50000] when 'chapeu_f' then array[50000]
      when 'extra_m' then array[3000,10000,8000,6000] when 'extra_f' then array[3000,10000,8000,4000,15000,20000,7000] end)[p_item - 39], 999999)
    when p_item >= 30 then 999999
    when p_item < (case when p_peca = 'estampa' then 2 else 4 end) then 0
    else (round(30 * power(1.15, p_item - (case when p_peca = 'estampa' then 2 else 4 end)) / 10) * 10)::integer end
$$;
create or replace function public.comprar_roupa(p_peca text, p_item integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; pr integer;
begin
  m := _eu();
  if p_peca not in ('roupa_m','roupa_f','calca_m','calca_f','calcado_m','calcado_f','chapeu_m','chapeu_f','extra_m','extra_f','estampa') then raise exception 'Peça inválida.'; end if;
  if p_item < 0 or p_item >= 50 then raise exception 'Peça inválida.'; end if;
  if p_item >= 30 and p_item < 40 then raise exception 'Esse item é exclusivo do Passe da Temporada.'; end if;
  if exists (select 1 from guarda_roupa where morador = m.id and peca = p_peca and item = p_item) then return json_build_object('ok', true, 'eu', _estado(m.id)); end if;
  pr := preco_roupa(p_peca, p_item);
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente.'; end if;
  insert into guarda_roupa(morador, peca, item) values (m.id, p_peca, p_item);
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_roupa(text, integer) to authenticated;
