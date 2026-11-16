-- banco- 4 de 16. Rode na ordem.
create or replace function public.comecar_trabalho(p_trabalho text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; morreu boolean;
begin
  m := _eu();
  select * into t from trabalhos where id = p_trabalho;
  if not found then raise exception 'Esse trabalho não existe.'; end if;
  if m.nivel < t.nivel_min then raise exception 'Esse trabalho libera no nível %.', t.nivel_min; end if;
  morreu := _gastar_fome(m.id, 0);
  if morreu then return json_build_object('morreu', true, 'eu', _estado(m.id)); end if;
  if (select fome from moradores where id = m.id) < 15 then
    raise exception 'Você está fraco de fome. Coma alguma coisa antes de trabalhar.';
  end if;
  update moradores set trabalho = t.id, trabalho_inicio = now() where id = m.id;
  return json_build_object('trabalho', t.id, 'duracao', t.duracao, 'salario', t.salario, 'morreu', false, 'eu', _estado(m.id));
end $$;

create or replace function public.terminar_trabalho() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; falta numeric; pago integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  select * into t from trabalhos where id = m.trabalho;
  falta := t.duracao - extract(epoch from (now() - m.trabalho_inicio));
  if falta > 1 then raise exception 'Ainda faltam % segundos de turno.', ceil(falta); end if;
  pago := round(t.salario * (1 + 0.02 * (m.nivel - 1)));          -- +2% por nível
  if t.id = 'pescador' then peixes_ganhos := 1 + (random() < 0.4)::integer; end if;
  novo_xp := m.xp + t.xp;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;  -- R$ 50 × nível
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, trabalho = null, trabalho_inicio = null, turnos = turnos + 1
  where id = m.id;
  morreu := _gastar_fome(m.id, t.fome);
  return json_build_object('pago', pago, 'xp_ganho', t.xp, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.largar_trabalho() returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update moradores set trabalho = null, trabalho_inicio = null where id = m.id;
end $$;

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
  update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + i.fome) where id = m.id;
  return json_build_object('item', i.id, 'preco', i.preco, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.vender_peixes() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer;
begin
  m := _eu();
  if m.peixes < 1 then raise exception 'Você não tem peixe para vender.'; end if;
  ganho := m.peixes * 28;
  update moradores set dinheiro = dinheiro + ganho, peixes = 0 where id = m.id;
  return json_build_object('ganho', ganho, 'vendidos', m.peixes, 'eu', _estado(m.id));
end $$;

create or replace function public.comer_fruta(p_arvore integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ultima timestamptz; falta numeric;
begin
  m := _eu();
  if p_arvore < 1 or p_arvore > 50 then raise exception 'Essa árvore não existe.'; end if;
  select max(quando) into ultima from frutas where morador = m.id;
  if ultima is not null and now() - ultima < interval '20 seconds' then
    raise exception 'Calma, ainda está mastigando a última fruta.';
  end if;
  select 180 - extract(epoch from (now() - quando)) into falta from frutas where morador = m.id and arvore = p_arvore;
  if falta is not null and falta > 0 then raise exception 'Essa árvore ainda não tem fruta madura (faltam % s).', ceil(falta); end if;
  perform _gastar_fome(m.id, 0);
  insert into frutas(morador, arvore, quando) values (m.id, p_arvore, now())
    on conflict (morador, arvore) do update set quando = now();
  update moradores set fome = least(100, fome + 10) where id = m.id;
  return json_build_object('arvore', p_arvore, 'espera', 180, 'eu', _estado(m.id));
end $$;

create or replace function public.comprar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja;
begin
  m := _eu();
  select * into i from loja where id = p_carro and tipo = 'carro';
  if not found then raise exception 'Esse carro não existe.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Esse carro libera no nível %.', i.nivel_min; end if;
  if p_carro = any(m.carros) then raise exception 'Você já tem esse carro.'; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente para esse carro.'; end if;
  update moradores set dinheiro = dinheiro - i.preco, carros = array_append(carros, i.id), carro = i.id where id = m.id;
  return json_build_object('carro', i.id, 'eu', _estado(m.id));
end $$;

create or replace function public.usar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_carro is not null and not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  update moradores set carro = p_carro where id = m.id;
  update vagas set carro = p_carro where morador = m.id and p_carro is not null;
  return json_build_object('carro', p_carro);
end $$;

