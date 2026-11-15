-- Novidades: painel do administrador e venda de carros. Rode no Supabase.

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

-- TORNE-SE ADMINISTRADOR (troque pelo nome do seu personagem):
update public.moradores set admin = true where nome = 'SEU NOME AQUI';
