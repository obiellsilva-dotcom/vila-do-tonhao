-- banco- 8 de 16. Rode na ordem.
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

