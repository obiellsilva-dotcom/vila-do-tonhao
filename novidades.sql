-- ETAPAS 36 a 41: Luz de teto, estilo da casa, avisos pelo Cloudflare, economia (casas, Hillux, pacotes), apartamentos sem limite e títulos. Pode rodar de novo sem perder nada.
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000 else null end
$$;
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000
    when 'vaso' then 700 when 'piabanho' then 900 when 'chuveiro' then 1500 when 'banheira' then 3200 when 'toalheiro' then 400 when 'armpar' then 1100 when 'micro' then 1300 when 'cafeteira' then 800 when 'balcao' then 2600 when 'churras' then 3500 when 'rede' then 900 when 'cadpraia' then 450 when 'piscina' then 1800 when 'gamer' then 4500 when 'cadgamer' then 2200 when 'sofacurvo' then 4800 when 'sofamod' then 5600 when 'painel' then 2400 when 'mesaredonda' then 1300 when 'leitura' then 2000 when 'camaking' then 6500 when 'beliche' then 2400 when 'penteadeira' then 2100 when 'comoda' then 1500 when 'quadro' then 600 when 'quadro2' then 900 when 'espelho' then 1100 when 'taprd' then 700 when 'cortina' then 800 when 'lumichao' then 900 when 'relogio' then 500 when 'plantag' then 700 when 'trofeu' then 1500 when 'lustre' then 18000 when 'piano' then 28000 when 'estatua' then 15000 when 'sofacouro' then 12000 when 'adega' then 9500 when 'vitrola' then 7500 when 'trono' then 20000 when 'hidro' then 24000 when 'massag' then 16000 when 'arcade' then 14000 when 'aqparede' then 22000 when 'lareira' then 8000 when 'globo' then 6000 when 'neon' then 5000 when 'neon2' then 3500 when 'fonte' then 9000 when 'lava' then 2500 when 'luzteto' then 250 else null end
$$;

-- ===================== ETAPA 37: Estilo da casa (cor das paredes, piso e janelas) =====================
-- p = cor da parede (0 a 11, R$ 300), c = piso (0 a 13, R$ 600; 12 e 13 só VIP), j = janela (0 a 6, R$ 400)
alter table public.casas add column if not exists estilo jsonb not null default '{}'::jsonb;

create or replace function public.estilo_casa(p_casa integer, p_tipo text, p_v integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer; mx integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id for update;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  pr := case p_tipo when 'p' then 300 when 'c' then 600 when 'j' then 400 else null end;
  mx := case p_tipo when 'p' then 11 when 'c' then 13 when 'j' then 6 else null end;
  if pr is null or p_v is null or p_v < 0 or p_v > mx then raise exception 'Opção inválida.'; end if;
  if p_tipo = 'c' and p_v >= 12 and not (m.vip_ate is not null and m.vip_ate > now()) then raise exception 'Esse piso é só para VIP.'; end if;
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', pr; end if;
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  update casas set estilo = coalesce(estilo, '{}'::jsonb) || jsonb_build_object(p_tipo, p_v) where id = c.id;
  return json_build_object('estilo', (select estilo from casas where id = c.id), 'eu', _estado(m.id));
end $$;
revoke execute on function public.estilo_casa(integer, text, integer) from public, anon;
grant execute on function public.estilo_casa(integer, text, integer) to authenticated;

-- ===================== ETAPA 38: avisos de casa e vaga pelo Cloudflare (tira o tempo real do Supabase) =====================
-- Quando uma casa muda de dono/porta ou uma vaga muda, o banco avisa o servidor ao vivo, que avisa todas as salas.
create extension if not exists pg_net;
create or replace function public._aviso_rt() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(url := 'https://vila-tempo-real.obiellsilva.workers.dev/glob',
    body := jsonb_build_object('tb', TG_TABLE_NAME, 'id', NEW.id), headers := '{"Content-Type":"application/json"}'::jsonb);
  return NEW;
exception when others then return NEW;
end $$;
revoke execute on function public._aviso_rt() from public, anon, authenticated;
drop trigger if exists casas_aviso_rt on public.casas;
create trigger casas_aviso_rt after update on public.casas for each row
  when (old.dono is distinct from new.dono or old.aberta is distinct from new.aberta) execute function public._aviso_rt();
drop trigger if exists vagas_aviso_rt on public.vagas;
create trigger vagas_aviso_rt after update on public.vagas for each row
  when (old.morador is distinct from new.morador or old.carro is distinct from new.carro) execute function public._aviso_rt();

-- ===================== ETAPA 39: economia (casas mais caras, Hillux, pacotes de dinheiro) =====================
-- o "tipo" da casa (1 de cada) passa a usar os preços novos
drop index if exists public.casas_um_por_tipo;
alter table public.casas drop column if exists tipo;
alter table public.casas add column tipo text generated always as (case when id > 1000 then 'apto' when preco >= 200000 then 'mansao' when preco >= 40000 then 'media' else 'barata' end) stored;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;
-- casas da cidade: 12 mil -> 30 mil, 18 mil -> 45 mil, 30 mil -> 75 mil, 135 mil -> 350 mil (roda uma vez só)
do $$ begin
  if not exists (select 1 from migracoes where id = 'casas_eco2') then
    update casas set preco = case when preco < 15000 then 30000 when preco < 25000 then 45000 when preco < 100000 then 75000 else 350000 end where id < 1000;
    insert into migracoes(id) values ('casas_eco2');
  end if;
end $$;
-- apartamentos: kitnet 15 mil (aluguel 1.500/semana), 2 quartos 25 mil (2.500/semana)
update casas set preco = case when ((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1) then 15000 else 25000 end,
  valor_aluguel = case when ((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1) then 1500 else 2500 end where id > 1000;
alter table public.produtos drop constraint if exists produtos_tipo_check;
alter table public.produtos add constraint produtos_tipo_check check (tipo in ('vip','pet','carro','passe','dinheiro'));
-- Hillux (antiga Caminhonete do Tonhão)
update produtos set nome = 'Hillux', preco = 15.90 where id = 'carro_kombi_tonhao';
-- pacotes de dinheiro do jogo (item = quanto entrega)
insert into produtos(id, tipo, item, dias, nome, preco) values
  ('din10', 'dinheiro', '10000', 0, 'R$ 10 mil do jogo', 9.90),
  ('din20', 'dinheiro', '20000', 0, 'R$ 20 mil do jogo', 18.90),
  ('din50', 'dinheiro', '50000', 0, 'R$ 50 mil do jogo', 44.90),
  ('din100', 'dinheiro', '100000', 0, 'R$ 100 mil do jogo', 84.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, nome = excluded.nome, preco = excluded.preco;
-- limite: no máximo R$ 100 mil do jogo comprados em 7 dias (conferido quando o Pix é gerado)
create or replace function public._limite_dinheiro() returns trigger
language plpgsql security definer set search_path = public as $$
declare novo integer; ja integer;
begin
  select case when tipo = 'dinheiro' then item::integer else 0 end into novo from produtos where id = NEW.produto;
  if coalesce(novo, 0) = 0 then return NEW; end if;
  select coalesce(sum(pr.item::integer), 0) into ja from pedidos p join produtos pr on pr.id = p.produto
    where p.morador = NEW.morador and pr.tipo = 'dinheiro' and p.status = 'entregue' and p.pago_em > now() - interval '7 days';
  if ja + novo > 100000 then raise exception 'Limite de R$ 100 mil do jogo por semana. Já comprado: R$ %.', ja; end if;
  return NEW;
end $$;
revoke execute on function public._limite_dinheiro() from public, anon, authenticated;
drop trigger if exists pedidos_limite_dinheiro on public.pedidos;
create trigger pedidos_limite_dinheiro before insert on public.pedidos for each row execute function public._limite_dinheiro();
-- entrega do Pix agora também entrega dinheiro
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
  elsif pr.tipo = 'dinheiro' then
    update moradores set dinheiro = dinheiro + pr.item::integer where id = pd.morador;
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;

-- ===================== ETAPA 40: apartamentos sem limite =====================
-- Quando sobram menos de 4 apartamentos livres de um tipo, o banco cria um bloco novo com 16 (E, F, G...).
-- Blocos ímpares a partir do E = kitnet; pares = 2 quartos. Eles ficam nos mesmos prédios do condomínio.
create or replace function public._garante_aptos() returns void
language plpgsql security definer set search_path = public as $$
declare k boolean; livres integer; b integer; tentativas integer := 0;
begin
  foreach k in array array[true, false] loop
    loop
      select count(*) into livres from casas where id > 1000 and dono is null
        and (((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1)) = k;
      exit when livres >= 4 or tentativas >= 4;
      tentativas := tentativas + 1;
      select coalesce(max((id - 1000) / 100), 4) + 1 into b from casas where id > 1000;
      if b > 89 then exit; end if;
      insert into casas(id, preco, nivel_min, valor_aluguel)
      select 1000 + b * 100 + a * 10 + f, case when b % 2 = 1 then 15000 else 25000 end, 1, case when b % 2 = 1 then 1500 else 2500 end
      from generate_series(1, 4) a, generate_series(1, 4) f on conflict (id) do nothing;
    end loop;
  end loop;
end $$;
revoke execute on function public._garante_aptos() from public, anon, authenticated;
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
  perform _garante_aptos();
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;
revoke execute on function public._pegar_apto(integer, boolean) from public, anon, authenticated;
select _garante_aptos();

-- ===================== ETAPA 41: títulos e conquistas =====================
alter table public.moradores add column if not exists titulo text;
alter table public.moradores add column if not exists titulos text[] not null default '{}';
alter table public.moradores add column if not exists tarefas_total integer not null default 0;
alter table public.moradores add column if not exists ganho_trabalho bigint not null default 0;

-- conta cada tarefa e o dinheiro ganho trabalhando (toda tarefa grava "tarefa_em")
create or replace function public._conta_tarefa() returns trigger
language plpgsql as $$
begin
  new.tarefas_total := coalesce(old.tarefas_total, 0) + 1;
  new.ganho_trabalho := coalesce(old.ganho_trabalho, 0) + greatest(0, new.dinheiro - old.dinheiro);
  return new;
end $$;
drop trigger if exists moradores_conta_tarefa on public.moradores;
create trigger moradores_conta_tarefa before update on public.moradores for each row
  when (new.tarefa_em is distinct from old.tarefa_em) execute function public._conta_tarefa();

-- códigos que dão título (ex.: testadores). Só o dono cria, direto no banco.
create table if not exists public.codigos (id text primary key, titulo text not null, ate timestamptz not null, usos integer not null default 0);
alter table public.codigos enable row level security;
insert into public.codigos(id, titulo, ate) values ('PIONEIRO-VILA', 'pioneiro', '2027-02-28 23:59:59-03') on conflict (id) do nothing;

-- quais títulos a pessoa já conquistou
create or replace function public._titulos_de(p_id uuid) returns text[]
language plpgsql stable security definer set search_path = public as $$
declare m public.moradores; t text[]; gasto numeric; nc integer;
begin
  select * into m from moradores where id = p_id;
  if not found then return '{}'; end if;
  t := coalesce(m.titulos, '{}');
  nc := coalesce(cardinality(m.carros), 0);
  if exists (select 1 from casas where dono = m.id) then t := array_append(t, 'morador'); end if;
  if m.tarefas_total >= 100 then t := array_append(t, 'trabalhador'); end if;
  if m.tarefas_total >= 1000 then t := array_append(t, 'dedicado'); end if;
  if m.tarefas_total >= 5000 then t := array_append(t, 'incansavel'); end if;
  if m.tarefas_total >= 20000 then t := array_append(t, 'imparavel'); end if;
  if nc >= 1 then t := array_append(t, 'motorista'); end if;
  if nc >= 5 then t := array_append(t, 'colecionador'); end if;
  if m.nivel >= 20 then t := array_append(t, 'veterano'); end if;
  if m.nivel >= 35 then t := array_append(t, 'lenda'); end if;
  if m.nivel >= 50 then t := array_append(t, 'mestre'); end if;
  if m.ganho_trabalho >= 1000000 then t := array_append(t, 'milionario'); end if;
  if nc >= 8 and exists (select 1 from casas where dono = m.id and tipo = 'mansao') then t := array_append(t, 'magnata'); end if;
  select coalesce(sum(valor), 0) into gasto from pedidos where morador = m.id and status = 'entregue';
  if gasto >= 300 then t := array_append(t, 'apoiador3'); elsif gasto >= 100 then t := array_append(t, 'apoiador2'); elsif gasto >= 20 then t := array_append(t, 'apoiador1'); end if;
  return t;
end $$;
revoke execute on function public._titulos_de(uuid) from public, anon, authenticated;

create or replace function public.meus_titulos() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  return json_build_object('titulos', _titulos_de(m.id), 'titulo', m.titulo, 'tarefas', m.tarefas_total, 'ganho', m.ganho_trabalho);
end $$;
grant execute on function public.meus_titulos() to authenticated;

create or replace function public.usar_titulo(p_titulo text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_titulo is not null and not (p_titulo = any(_titulos_de(m.id))) then raise exception 'Você ainda não tem esse título.'; end if;
  update moradores set titulo = p_titulo where id = m.id;
  return json_build_object('titulo', p_titulo);
end $$;
grant execute on function public.usar_titulo(text) to authenticated;

create or replace function public.resgatar_codigo(p_codigo text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.codigos;
begin
  m := _eu();
  select * into c from codigos where id = upper(trim(p_codigo)) and ate > now() for update;
  if not found then raise exception 'Código inválido ou vencido.'; end if;
  if c.titulo = any(m.titulos) then raise exception 'Você já tem esse título.'; end if;
  update moradores set titulos = array_append(titulos, c.titulo) where id = m.id;
  update codigos set usos = usos + 1 where id = c.id;
  return json_build_object('titulo', c.titulo);
end $$;
grant execute on function public.resgatar_codigo(text) to authenticated;
