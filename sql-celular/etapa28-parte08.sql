-- ETAPA 28, parte 8 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
create or replace function public.usar_rastro(p_rastro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_rastro is not null and p_rastro not in ('ouro','natal','nenhum') then raise exception 'Brilho inválido.'; end if;
  if p_rastro = 'ouro' and not coalesce(m.vip_ate > now(), false) then raise exception 'O brilho dourado é do VIP.'; end if;
  if p_rastro = 'natal' and not exists (select 1 from guarda_roupa where morador = m.id and peca = 'rastro' and item = 1) then raise exception 'O brilho de Natal é do Passe Natal na Vila.'; end if;
  update moradores set rastro = p_rastro where id = m.id;
  return json_build_object('rastro', p_rastro);
end $$;
grant execute on function public.usar_rastro(text) to authenticated;
create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'gasolina', round(gasolina, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet, 'rastro', rastro)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

-- ===== sinuca: 15 bolas no modo sozinho e XP também no amistoso em dupla =====
create or replace function public.sinuca(p_bolas integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean;
begin
  m := _eu();
  if p_bolas < 0 or p_bolas > 15 then raise exception 'Placar inválido.'; end if;
  if m.sinuca_em is not null and now() - m.sinuca_em < interval '90 seconds' then
    raise exception 'A mesa está ocupada. Próxima partida valendo XP em % s.', ceil(90 - extract(epoch from (now() - m.sinuca_em)));
  end if;
  ganho := p_bolas * 3;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set xp = novo_xp, nivel = novo_nivel, dinheiro = dinheiro + premio, sinuca_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, 2);
  return json_build_object('xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio, 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.sinuca(integer) to authenticated;
