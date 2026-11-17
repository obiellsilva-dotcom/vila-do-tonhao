-- ETAPA 28, parte 9 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
create or replace function public.sinuca_dupla(p_venceu boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer; novo_xp integer; novo_nivel integer; premio integer := 0;
begin
  m := _eu();
  if m.sinuca_em is not null and now() - m.sinuca_em < interval '90 seconds' then
    raise exception 'XP da sinuca só a cada 90 s.';
  end if;
  ganho := case when p_venceu then 30 else 10 end;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set xp = novo_xp, nivel = novo_nivel, dinheiro = dinheiro + premio, sinuca_em = now() where id = m.id;
  return json_build_object('xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio, 'eu', _estado(m.id));
end $$;
revoke execute on function public.sinuca_dupla(boolean) from public, anon;
grant execute on function public.sinuca_dupla(boolean) to authenticated;

-- aluguel: só grava quando cobrou de verdade (cada gravação em "casas" é avisada a todos os jogadores pelo Realtime)
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
  if pago > 0 then
    update moradores set dinheiro = m.dinheiro where id = m.id;
    update casas set aluguel_ate = c.aluguel_ate where id = c.id;
  end if;
  if c.aluguel_ate < now() - interval '3 days' then
    perform _vagar_apto(c.id);
    return json_build_object('despejado', true, 'pago', pago, 'eu', _estado(m.id));
  end if;
  return json_build_object('pago', pago, 'atrasado', c.aluguel_ate < now(), 'valor', c.valor_aluguel, 'eu', _estado(m.id));
end $$;
grant execute on function public.cobrar_aluguel() to authenticated;
