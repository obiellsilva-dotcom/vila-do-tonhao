-- banco- 9 de 16. Rode na ordem.
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
