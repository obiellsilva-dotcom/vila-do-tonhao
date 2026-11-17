-- Novidades: ETAPAS 26 (patrulha da polícia) e 27 (excluir conta). As etapas 21 a 25 já foram rodadas.

-- ===================== ETAPA 26: patrulha da polícia sem limite (R$ 50 + 20 XP a cada 1 min e meio) =====================
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
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 50, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;
revoke execute on function public.ronda_policia() from public, anon;
grant execute on function public.ronda_policia() to authenticated;

-- ===================== ETAPA 27: excluir a própria conta (exigência da Play Store) =====================
-- Apaga o login; o personagem, chat, posts, seguidores, roupas, frutas, denúncias, propostas e pedidos somem junto (cascade).
-- A casa/apartamento fica livre e sem móveis. As fotos são apagadas pelo jogo antes (Storage); aqui tenta de novo por garantia.
create or replace function public.excluir_conta() returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'Entre na sua conta primeiro.'; end if;
  update casas set dono = null, comprada_em = null, aberta = false, alugada = false, aluguel_ate = null,
    moveis = '[]'::jsonb, geladeira = '{}'::jsonb where dono = u;
  update cidade set prefeito = null, desde = null where prefeito = u;
  begin
    delete from storage.objects where bucket_id = 'fotos' and (storage.foldername(name))[1] = u::text;
  exception when others then null;
  end;
  delete from moradores where id = u;
  delete from auth.users where id = u;
  return json_build_object('ok', true);
end $$;
revoke execute on function public.excluir_conta() from public, anon;
grant execute on function public.excluir_conta() to authenticated;
