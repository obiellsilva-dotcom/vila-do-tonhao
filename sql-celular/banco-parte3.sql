-- Banco completo, parte 3 de 4. Rode na ordem (1, 2, 3, 4).
-- ===================== ETAPA 6: perfil social (seguidores e fotos) =====================
create table if not exists public.seguidores (
  seguidor uuid not null references public.moradores(id) on delete cascade,
  seguido  uuid not null references public.moradores(id) on delete cascade,
  criado_em timestamptz not null default now(),
  primary key (seguidor, seguido),
  check (seguidor <> seguido)
);
create index if not exists seguidores_seguido on public.seguidores(seguido);

create table if not exists public.posts (
  id bigserial primary key,
  autor uuid not null references public.moradores(id) on delete cascade,
  url text not null,
  legenda text,
  criado_em timestamptz not null default now()
);
create index if not exists posts_autor on public.posts(autor, criado_em desc);

alter table public.seguidores enable row level security;
alter table public.posts      enable row level security;
drop policy if exists "ler seguidores" on public.seguidores;
create policy "ler seguidores" on public.seguidores for select using (true);
drop policy if exists "ler posts" on public.posts;
create policy "ler posts" on public.posts for select using (true);
revoke insert, update, delete on public.seguidores, public.posts from anon, authenticated;

-- Seguir ou deixar de seguir alguém
create or replace function public.seguir(p_alvo uuid, p_seguir boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_alvo = m.id then raise exception 'Você não pode seguir você mesmo.'; end if;
  if not exists (select 1 from moradores where id = p_alvo) then raise exception 'Morador não encontrado.'; end if;
  if p_seguir then insert into seguidores(seguidor, seguido) values (m.id, p_alvo) on conflict do nothing;
  else delete from seguidores where seguidor = m.id and seguido = p_alvo; end if;
  return json_build_object('seguindo', p_seguir, 'seguidores', (select count(*) from seguidores where seguido = p_alvo));
end $$;
grant execute on function public.seguir(uuid, boolean) to authenticated;

-- Postar foto (o arquivo vai para a pasta "fotos/<seu id>/"); até 10 posts por dia
create or replace function public.postar(p_url text, p_legenda text) returns public.posts
language plpgsql security definer set search_path = public as $$
declare m public.moradores; l text := nullif(btrim(coalesce(p_legenda,'')), ''); r public.posts;
begin
  m := _eu();
  if m.banido then raise exception 'Você foi banido.'; end if;
  if char_length(p_url) > 400 or p_url !~ ('^https://[a-z0-9.-]+/storage/v1/object/public/fotos/' || m.id::text || '/post-[0-9]+\.jpg$') then
    raise exception 'Foto inválida.'; end if;
  if char_length(l) > 120 then raise exception 'A legenda pode ter até 120 letras.'; end if;
  if (select count(*) from posts where autor = m.id and criado_em > now() - interval '1 day') >= 10 then
    raise exception 'Limite de 10 fotos por dia. Volte amanhã!'; end if;
  insert into posts(autor, url, legenda) values (m.id, p_url, limpar_texto(l)) returning * into r;
  return r;
end $$;
grant execute on function public.postar(text, text) to authenticated;

-- Apagar um post seu
create or replace function public.apagar_post(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  delete from posts where id = p_id and autor = m.id;
end $$;
grant execute on function public.apagar_post(bigint) to authenticated;

-- ===================== ETAPA 7: empregos pagam por tarefa =====================
-- Cada tarefa concluída paga dinheiro e XP na hora. Quanto maior o salário/XP do emprego e o seu
-- nível acima do mínimo do emprego, mais cada tarefa paga. Máximo de 1 tarefa a cada 2,5 segundos.
alter table public.moradores add column if not exists tarefa_em timestamptz;

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
  ganho := greatest(1, round(t.xp / 20.0 * (1 + 0.04 * extra)));  -- XP reduzido (era /6)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;
grant execute on function public.tarefa_feita() to authenticated;

-- ===================== ETAPA 8: cor dos carros (escolhida na concessionária) =====================
alter table public.moradores add column if not exists carro_cores jsonb not null default '{}'::jsonb;

create or replace function public.cor_carro(p_carro text, p_cor text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_cor not in ('#3c78d8','#c0392b','#2b2b30','#eeeeee','#aeb3b8','#f1c40f','#27ae60','#e67e22','#e84393','#7b241c') then
    raise exception 'Cor inválida.'; end if;
  update moradores set carro_cores = carro_cores || jsonb_build_object(p_carro, p_cor) where id = m.id;
  return json_build_object('ok', true);
end $$;
grant execute on function public.cor_carro(text, text) to authenticated;

-- ===================== ETAPA 9: mochila (inventário) =====================
alter table public.moradores add column if not exists mochila jsonb not null default '{}'::jsonb;

-- Compra e guarda na mochila (até 20 de cada)
create or replace function public.guardar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer;
begin
  m := _eu();
  select * into i from loja where id = p_item and tipo = 'consumo';
  if not found or p_item = 'rodada' then raise exception 'Isso não dá para guardar.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Libera no nível %.', i.nivel_min; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente. Vai trabalhar! 😅'; end if;
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q >= 20 then raise exception 'Sua mochila já tem 20 desse item.'; end if;
  update moradores set dinheiro = dinheiro - i.preco, mochila = mochila || jsonb_build_object(p_item, q + 1) where id = m.id;
  return json_build_object('item', i.id, 'mochila', (select mochila from moradores where id = m.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.guardar_item(text) to authenticated;

-- Usa um item da mochila (come ou bebe em qualquer lugar)
create or replace function public.usar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer; morreu boolean;
begin
  m := _eu();
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
  select * into i from loja where id = p_item;
  morreu := _gastar_fome(m.id, 0);
  update moradores set fome = least(100, fome + coalesce(i.fome, 0)),
    mochila = case when q > 1 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end
  where id = m.id;
  return json_build_object('item', p_item, 'mochila', (select mochila from moradores where id = m.id), 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.usar_item(text) to authenticated;

-- ===================== ETAPA 10: prefeito da cidade =====================
create table if not exists public.cidade (
  id integer primary key default 1 check (id = 1),
  prefeito uuid references public.moradores(id) on delete set null,
  desde timestamptz
);
insert into public.cidade(id) values (1) on conflict (id) do nothing;
alter table public.cidade enable row level security;
drop policy if exists "ler cidade" on public.cidade;
create policy "ler cidade" on public.cidade for select using (true);
revoke insert, update, delete on public.cidade from anon, authenticated;
update public.trabalhos set nivel_min = 1 where id = 'prefeito';

-- Assume o cargo: só quem tem o maior nível entre os jogadores online
create or replace function public.assumir_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; maior integer; atual public.moradores;
begin
  m := _eu();
  select max(nivel) into maior from moradores where not banido and visto_em > now() - interval '8 minutes';
  if m.nivel < coalesce(maior, 0) then
    raise exception 'Só quem tem o MAIOR nível online pode ser prefeito (agora é o nível %).', maior; end if;
  select mo.* into atual from cidade c join moradores mo on mo.id = c.prefeito where c.id = 1;
  if atual.id = m.id then raise exception 'Você já é o prefeito!'; end if;
  if atual.id is not null and atual.visto_em > now() - interval '8 minutes' and atual.nivel >= m.nivel then
    raise exception 'O prefeito % está online e tem nível igual ou maior.', atual.nome; end if;
  update cidade set prefeito = m.id, desde = now() where id = 1;
  return json_build_object('prefeito', m.id, 'nome', m.nome);
end $$;
grant execute on function public.assumir_prefeitura() to authenticated;

create or replace function public.comecar_trabalho(p_trabalho text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; morreu boolean;
begin
  m := _eu();
  select * into t from trabalhos where id = p_trabalho;
  if not found then raise exception 'Esse trabalho não existe.'; end if;
  if m.nivel < t.nivel_min then raise exception 'Esse trabalho libera no nível %.', t.nivel_min; end if;
  if t.id = 'prefeito' and coalesce((select prefeito from cidade where id = 1)::text, '') <> m.id::text then
    raise exception 'Só o prefeito da cidade trabalha aqui. Vá na prefeitura e assuma o cargo!'; end if;
  morreu := _gastar_fome(m.id, 0);
  if morreu then return json_build_object('morreu', true, 'eu', _estado(m.id)); end if;
  if (select fome from moradores where id = m.id) < 15 then
    raise exception 'Você está fraco de fome. Coma alguma coisa antes de trabalhar.';
  end if;
  update moradores set trabalho = t.id, trabalho_inicio = now() where id = m.id;
  return json_build_object('trabalho', t.id, 'duracao', t.duracao, 'salario', t.salario, 'morreu', false, 'eu', _estado(m.id));
end $$;

-- ===================== ETAPA 11: painel do administrador e venda de carros =====================
alter table public.moradores add column if not exists admin boolean not null default false;

create or replace function public._adm() returns public.moradores
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not m.admin then raise exception 'Só o administrador pode fazer isso.'; end if;
  return m;
end $$;
revoke execute on function public._adm() from public, anon, authenticated;

create or replace function public._alvo(p_nome text) returns public.moradores
language plpgsql security definer set search_path = public as $$
declare a public.moradores;
begin
  select * into a from moradores where lower(nome) = lower(btrim(p_nome)) limit 1 for update;
  if not found then raise exception 'Jogador "%" não encontrado.', p_nome; end if;
  return a;
end $$;
revoke execute on function public._alvo(text) from public, anon, authenticated;

-- uma função só para o painel: p_acao = dinheiro | vip | pet | carro | casa | banir | desbanir | tirar_casa
create or replace function public.admin_acao(p_nome text, p_acao text, p_valor text) returns json
language plpgsql security definer set search_path = public as $$
declare a public.moradores; n integer; c public.casas;
begin
  perform _adm();
  a := _alvo(p_nome);
  if p_acao = 'dinheiro' then
    n := p_valor::integer;
    update moradores set dinheiro = greatest(0, dinheiro + n) where id = a.id;
  elsif p_acao = 'vip' then
    n := greatest(1, p_valor::integer);
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => n) where id = a.id;
  elsif p_acao = 'pet' then
    if p_valor not in ('cachorro','gato','galinha','capivara','papagaio') then raise exception 'Pet inválido.'; end if;
    update moradores set pets = (select array_agg(distinct x) from unnest(array_append(pets, p_valor)) x), pet = p_valor where id = a.id;
  elsif p_acao = 'carro' then
    update moradores set carros = (select array_agg(distinct x) from unnest(array_append(carros, p_valor)) x), carro = p_valor where id = a.id;
  elsif p_acao = 'casa' then
    select * into c from casas where id = p_valor::integer for update;
    if not found then raise exception 'Casa não existe.'; end if;
    update vagas set morador = null, carro = null, desde = null where casa in (select id from casas where dono = a.id);
    update casas set dono = null, comprada_em = null, aberta = false where dono = a.id;
    update casas set dono = a.id, comprada_em = now(), aberta = false where id = c.id;
    update moradores set casa_id = c.id where id = a.id;
  elsif p_acao = 'tirar_casa' then
    update casas set dono = null, comprada_em = null, aberta = false where dono = a.id;
    update moradores set casa_id = null where id = a.id;
  elsif p_acao = 'banir' then
    update moradores set banido = true where id = a.id;
  elsif p_acao = 'desbanir' then
    update moradores set banido = false where id = a.id;
  else raise exception 'Ação desconhecida.'; end if;
  return json_build_object('ok', true, 'id', a.id, 'nome', a.nome);
end $$;
grant execute on function public.admin_acao(text, text, text) to authenticated;

-- vender o carro para a concessionária (metade do preço)
create or replace function public.vender_carro_loja(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; v integer;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  select * into i from loja where id = p_carro and tipo = 'carro';
  if not found then raise exception 'A concessionária não compra esse carro (é da loja VIP). Venda para outro jogador!'; end if;
  v := i.preco / 2;
  update vagas set morador = null, carro = null, desde = null where morador = m.id and carro = p_carro;
  update moradores set carros = array_remove(carros, p_carro), carro = case when carro = p_carro then null else carro end,
    carro_cores = carro_cores - p_carro, dinheiro = dinheiro + v where id = m.id;
  return json_build_object('recebido', v, 'eu', _estado(m.id));
end $$;
grant execute on function public.vender_carro_loja(text) to authenticated;

-- propostas de venda entre jogadores
create table if not exists public.propostas (
  id bigserial primary key,
  vendedor uuid not null references public.moradores(id) on delete cascade,
  comprador uuid not null references public.moradores(id) on delete cascade,
  carro text not null,
  valor integer not null check (valor >= 0),
  criado_em timestamptz not null default now()
);
alter table public.propostas enable row level security;
revoke insert, update, delete on public.propostas from anon, authenticated;

create or replace function public.propor_venda(p_nome text, p_carro text, p_valor integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; b public.moradores; pid bigint;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_valor < 0 or p_valor > 10000000 then raise exception 'Valor inválido.'; end if;
  select * into b from moradores where lower(nome) = lower(btrim(p_nome)) limit 1;
  if not found then raise exception 'Jogador "%" não encontrado.', p_nome; end if;
  if b.id = m.id then raise exception 'Não dá para vender para você mesmo.'; end if;
  if p_carro = any(b.carros) then raise exception '% já tem esse carro.', b.nome; end if;
  delete from propostas where vendedor = m.id and carro = p_carro;
  insert into propostas(vendedor, comprador, carro, valor) values (m.id, b.id, p_carro, p_valor) returning id into pid;
  return json_build_object('id', pid, 'comprador', b.id, 'nome', b.nome);
end $$;
grant execute on function public.propor_venda(text, text, integer) to authenticated;

create or replace function public.responder_proposta(p_id bigint, p_aceitar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; p public.propostas; v public.moradores; cor text;
begin
  m := _eu();
  select * into p from propostas where id = p_id and comprador = m.id for update;
  if not found then raise exception 'Essa proposta não existe mais.'; end if;
  delete from propostas where id = p.id;
  if not p_aceitar then return json_build_object('ok', false); end if;
  if p.criado_em < now() - interval '30 minutes' then raise exception 'A proposta expirou.'; end if;
  select * into v from moradores where id = p.vendedor for update;
  if not (p.carro = any(v.carros)) then raise exception 'O vendedor não tem mais esse carro.'; end if;
  if p.carro = any(m.carros) then raise exception 'Você já tem esse carro.'; end if;
  if m.dinheiro < p.valor then raise exception 'Dinheiro insuficiente.'; end if;
  cor := v.carro_cores->>p.carro;
  update vagas set morador = null, carro = null, desde = null where morador = v.id and carro = p.carro;
  update moradores set carros = array_remove(carros, p.carro), carro = case when carro = p.carro then null else carro end,
    carro_cores = carro_cores - p.carro, dinheiro = dinheiro + p.valor where id = v.id;
  update moradores set carros = array_append(carros, p.carro), carro = p.carro, dinheiro = dinheiro - p.valor,
    carro_cores = case when cor is null then carro_cores else carro_cores || jsonb_build_object(p.carro, cor) end where id = m.id;
  return json_build_object('ok', true, 'carro', p.carro, 'eu', _estado(m.id));
end $$;
grant execute on function public.responder_proposta(bigint, boolean) to authenticated;
-- ===================== ETAPA 13: sede e comidas novas =====================
alter table public.moradores add column if not exists sede numeric not null default 100;
alter table public.loja add column if not exists sede integer not null default 0;   -- quanto mata a sede

-- bebidas que já existiam agora matam a sede
update public.loja set sede = 25 where id = 'cerveja';
update public.loja set sede = 10 where id = 'pinga';
update public.loja set sede = 30 where id = 'guarana';
update public.loja set sede = 12 where id = 'cafe';
update public.loja set sede = 25 where id = 'rodada';

-- comidas e bebidas novas (baratas)
insert into public.loja(id, tipo, nome, preco, local, fome, sede, nivel_min) values
  ('agua',      'consumo', 'uma garrafa de água',     3, 'mercadinho',  0, 40, 1),
  ('banana',    'consumo', 'um cacho de banana',      3, 'mercadinho', 10,  2, 1),
  ('laranja',   'consumo', 'umas laranjas',           4, 'mercadinho',  8, 15, 1),
  ('melancia',  'consumo', 'uma fatia de melancia',   5, 'mercadinho', 10, 25, 1),
  ('biscoito',  'consumo', 'um pacote de biscoito',   6, 'mercadinho', 15,  0, 1),
  ('queijo',    'consumo', 'um pedaço de queijo',     9, 'mercadinho', 22,  0, 1),
  ('sanduiche', 'consumo', 'um sanduíche natural',   12, 'mercadinho', 32,  5, 1),
  ('suco',      'consumo', 'um suco de laranja',      6, 'padaria',     4, 35, 1),
  ('agua_bar',  'consumo', 'um copo de água',         2, 'bar',         0, 30, 1)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, local = excluded.local,
  fome = excluded.fome, sede = excluded.sede;

-- fome e sede caem juntas (a sede um pouco mais rápido). Se uma das duas zerar, desmaia.
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; s numeric; seg numeric; base integer; ritmo numeric;
begin
  select * into m from moradores where id = p_id for update;
  ritmo := case when m.vip_ate > now() then 0.7 else 1 end;
  seg := least(extract(epoch from (now() - m.fome_em)), 90);
  f := m.fome - seg / 120.0 * ritmo - p_custo;
  s := m.sede - seg / 90.0 * ritmo - p_custo * 0.8;
  if f <= 0 or s <= 0 then
    base := xp_do_nivel(m.nivel);
    update moradores set fome = 50, sede = 50, fome_em = now(), visto_em = now(),
      xp = base + floor((m.xp - base) * 0.7), dinheiro = greatest(0, dinheiro - 30),
      mortes = mortes + 1, trabalho = null, trabalho_inicio = null
    where id = p_id;
    return true;
  end if;
  update moradores set fome = least(100, f), sede = least(100, s), fome_em = now(), visto_em = now() where id = p_id;
  return false;
end $$;
revoke execute on function public._gastar_fome(uuid, numeric) from authenticated, anon, public;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

create or replace function public.comprar(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; morreu boolean;
begin
  m := _eu();
  select * into i from loja where id = p_item and tipo = 'consumo';
  if not found then raise exception 'Isso não está à venda.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Libera no nível %.', i.nivel_min; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente. Vai trabalhar! 😅'; end if;
  morreu := _gastar_fome(m.id, 0);
  update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + i.fome), sede = least(100, sede + i.sede) where id = m.id;
  return json_build_object('item', i.id, 'preco', i.preco, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.usar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer; morreu boolean;
begin
  m := _eu();
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
  select * into i from loja where id = p_item;
  morreu := _gastar_fome(m.id, 0);
  update moradores set fome = least(100, fome + coalesce(i.fome, 0)), sede = least(100, sede + coalesce(i.sede, 0)),
    mochila = case when q > 1 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end
  where id = m.id;
  return json_build_object('item', p_item, 'mochila', (select mochila from moradores where id = m.id), 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.usar_item(text) to authenticated;

-- ===================== ETAPA 14: prefeito só no nível 20 =====================
update public.trabalhos set nivel_min = 20 where id = 'prefeito';

drop trigger if exists prefeito_top1 on public.moradores;
drop function if exists public._atualiza_prefeito() cascade;

create function public._atualiza_prefeito() returns trigger
language plpgsql security definer set search_path = public as $$
declare novo uuid;
begin
  select id into novo from moradores
   where nivel >= 20 and not coalesce(banido, false)
   order by xp desc, id limit 1;
  insert into cidade(id, prefeito, desde) values (1, novo, case when novo is null then null else now() end)
  on conflict (id) do update set prefeito = excluded.prefeito,
    desde = case when cidade.prefeito is distinct from excluded.prefeito then excluded.desde else cidade.desde end
  where cidade.prefeito is distinct from excluded.prefeito;
  return null;
end $$;
revoke execute on function public._atualiza_prefeito() from authenticated, anon, public;

create trigger prefeito_top1 after insert or update of xp, nivel, banido or delete on public.moradores
for each statement execute function public._atualiza_prefeito();


