-- Banco completo, parte 2 de 4. Rode na ordem (1, 2, 3, 4).
-- ===================== ETAPA 2: VIP, roupas novas, empregos e carros =====================

-- o estado do jogador agora inclui o VIP
create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;

-- criar/salvar morador: precisa de conta; aceita o visual antigo (TH) e o novo (TJ); peças 50+ só para VIP
create or replace function public.criar_morador(p_nome text, p_visual text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; n text := btrim(regexp_replace(coalesce(p_nome,''), '\s+', ' ', 'g'));
        v text := upper(coalesce(p_visual,'')); vip boolean;
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  if coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then raise exception 'Crie sua conta para jogar.'; end if;
  if char_length(n) < 1 or char_length(n) > 22 then raise exception 'O nome precisa ter de 1 a 22 letras.'; end if;
  if v !~ '^(TH[0-9]{7,30}|TJ[0-9]{20,30})$' or (v ~ '^TJ' and length(v) % 2 = 1) then raise exception 'Visual inválido.'; end if;
  if v ~ '^TJ' and exists (select 1 from generate_series(3, length(v) - 1, 2) i where substr(v, i, 2)::int >= 50) then
    select coalesce(vip_ate > now(), false) into vip from moradores where id = auth.uid();
    if not coalesce(vip, false) then raise exception '👑 Essa peça é exclusiva para VIP.'; end if;
  end if;
  n := public.limpar_texto(n);
  -- nome único: ninguém pode usar o nome de outra pessoa (não diferencia maiúsculas, minúsculas nem acentos)
  if n is distinct from (select nome from moradores where id = auth.uid())
     and exists (select 1 from moradores where id <> auth.uid() and lower(translate(nome,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) = lower(translate(n,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'))) then
    raise exception 'Já existe um morador com esse nome. Escolha outro.';
  end if;
  insert into moradores(id, nome, visual) values (auth.uid(), n, v)
  on conflict (id) do update set nome = excluded.nome, visual = excluded.visual, visto_em = now(),
    fome_em = case when now() - moradores.visto_em > interval '2 minutes' then now() else moradores.fome_em end
    where not moradores.banido
  returning * into m;
  if m.id is null then raise exception 'Você foi banido da cidade.'; end if;
  return _estado(m.id);
end $$;

-- empregos novos (níveis 13 a 20)
insert into public.trabalhos(id, nome, salario, duracao, nivel_min, xp, fome) values
  ('enfermeiro', 'Enfermeiro(a)',    125,  90, 13, 50, 14),
  ('gerente',    'Gerente do banco', 140, 100, 15, 56, 15),
  ('delegado',   'Delegado(a)',      155, 100, 17, 62, 16),
  ('medico',     'Médico(a)',        175, 110, 19, 70, 16),
  ('prefeito',   'Prefeito(a)',      200, 120, 20, 78, 16)
on conflict (id) do update set nome = excluded.nome, salario = excluded.salario, duracao = excluded.duracao,
  nivel_min = excluded.nivel_min, xp = excluded.xp, fome = excluded.fome;

-- carros novos
insert into public.loja(id, tipo, nome, preco, local, fome, nivel_min) values
  ('sedan',     'carro', 'Sedã',       45000, 'carros', 0, 13),
  ('jipe',      'carro', 'Jipe',       70000, 'carros', 0, 16),
  ('esportivo', 'carro', 'Esportivo', 120000, 'carros', 0, 20)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, nivel_min = excluded.nivel_min;

grant execute on function public.criar_morador(text, text) to authenticated;
revoke execute on function public._estado(uuid) from authenticated;

-- =====================================================================
--  EXTRAS (desligados: tire os "--" do começo da linha e rode só ela)
-- =====================================================================
-- DAR VIP por 30 dias:
-- update public.moradores set vip_ate = now() + interval '30 days' where nome = 'NOME DO JOGADOR';
-- TIRAR o VIP:
-- update public.moradores set vip_ate = null where nome = 'NOME DO JOGADOR';

-- ===================== ETAPA 3: benefícios VIP =====================
-- Fome cai 30% mais devagar para VIP (o custo do trabalho continua igual)
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; base integer; ritmo numeric;
begin
  select * into m from moradores where id = p_id for update;
  ritmo := case when m.vip_ate > now() then 0.7 else 1 end;
  f := m.fome - least(extract(epoch from (now() - m.fome_em)), 90) / 120.0 * ritmo - p_custo;
  if f <= 0 then
    base := xp_do_nivel(m.nivel);
    update moradores set fome = 50, fome_em = now(), visto_em = now(),
      xp = base + floor((m.xp - base) * 0.7), dinheiro = greatest(0, dinheiro - 30),
      mortes = mortes + 1, trabalho = null, trabalho_inicio = null
    where id = p_id;
    return true;
  end if;
  update moradores set fome = least(100, f), fome_em = now(), visto_em = now() where id = p_id;
  return false;
end $$;
revoke execute on function public._gastar_fome(uuid, numeric) from authenticated, anon, public;

-- ===================== ETAPA 4: interiores das casas =====================
-- O dono abre ou tranca a porta da casa (aberta = visitantes podem entrar)
create or replace function public.porta_casa(p_casa integer, p_aberta boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not exists (select 1 from casas where id = p_casa and dono = m.id) then raise exception 'Essa casa não é sua.'; end if;
  update casas set aberta = coalesce(p_aberta, false) where id = p_casa;
  return json_build_object('casa', p_casa, 'aberta', coalesce(p_aberta, false));
end $$;
grant execute on function public.porta_casa(integer, boolean) to authenticated;

-- ===================== ETAPA 5: loja com Pix (Mercado Pago) =====================
-- Produtos pagos com dinheiro de verdade. O preço vale AQUI (o jogo não decide o preço).
create table if not exists public.produtos (
  id     text primary key,
  tipo   text not null check (tipo in ('vip','pet','carro')),
  item   text,                       -- qual pet ou carro
  dias   integer not null default 0, -- dias de VIP
  nome   text not null,
  preco  numeric(10,2) not null check (preco > 0)
);
insert into public.produtos(id, tipo, item, dias, nome, preco) values
  ('vip30',              'vip',   null,           30, 'VIP 30 dias',         9.90),
  ('pet_cachorro',       'pet',   'cachorro',      0, 'Pet Cachorro',        5.90),
  ('pet_gato',           'pet',   'gato',          0, 'Pet Gato',            5.90),
  ('pet_galinha',        'pet',   'galinha',       0, 'Pet Galinha',         5.90),
  ('pet_capivara',       'pet',   'capivara',      0, 'Pet Capivara',        5.90),
  ('pet_papagaio',       'pet',   'papagaio',      0, 'Pet Papagaio',        5.90),
  ('carro_fusca_ouro',   'carro', 'fusca_ouro',    0, 'Fusca Dourado',       10.90),
  ('carro_kombi_tonhao', 'carro', 'kombi_tonhao',  0, 'Caminhonete do Tonhão', 12.90),
  ('carro_neon',         'carro', 'neon',          0, 'Esportivo Neon',      15.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, dias = excluded.dias,
  nome = excluded.nome, preco = excluded.preco;

create table if not exists public.pedidos (
  id         uuid primary key default gen_random_uuid(),
  morador    uuid not null references public.moradores(id) on delete cascade,
  produto    text not null references public.produtos(id),
  valor      numeric(10,2) not null,
  status     text not null default 'pendente' check (status in ('pendente','entregue','cancelado')),
  mp_id      text,
  criado_em  timestamptz not null default now(),
  pago_em    timestamptz
);
create index if not exists pedidos_morador on public.pedidos(morador, criado_em desc);

alter table public.produtos enable row level security;
alter table public.pedidos  enable row level security;
drop policy if exists "ler produtos" on public.produtos;
create policy "ler produtos" on public.produtos for select using (true);
drop policy if exists "ver meus pedidos" on public.pedidos;
create policy "ver meus pedidos" on public.pedidos for select to authenticated using (morador = auth.uid());
revoke insert, update, delete on public.produtos, public.pedidos from anon, authenticated;

-- Entrega o item de um pedido pago. Só a função do Pix (chave secreta do servidor) chama isto.
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
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;
grant execute on function public._entregar(uuid, text, numeric) to service_role;

-- Escolher qual pet anda com você (só pets que você comprou; null guarda o pet)
create or replace function public.usar_pet(p_pet text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_pet is not null and not (p_pet = any(m.pets)) then raise exception 'Esse pet não é seu.'; end if;
  update moradores set pet = p_pet where id = m.id;
  return json_build_object('pet', p_pet);
end $$;
grant execute on function public.usar_pet(text) to authenticated;

