-- ETAPA 28, parte 5 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
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
