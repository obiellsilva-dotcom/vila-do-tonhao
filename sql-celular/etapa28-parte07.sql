-- ETAPA 28, parte 7 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
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

-- brilho no chão (rastro): 'ouro' = do VIP, 'natal' = vermelho e verde do Passe Natal na Vila, 'nenhum' = desligado; null = padrão (ouro para VIP)
alter table public.moradores add column if not exists rastro text;
