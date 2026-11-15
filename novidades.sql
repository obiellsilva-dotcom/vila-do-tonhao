-- Novidade: primeira missão para quem acabou de chegar (bônus de R$ 50). Rode no Supabase (SQL Editor).

-- ===================== ETAPA 12: primeira missão (guia de quem acabou de chegar) =====================
-- missao: 0 = ainda não ganhou o primeiro dinheiro, 1 = recebeu o bônus e falta comer, 2 = terminou (ou pulou)
do $$ begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'moradores' and column_name = 'missao') then
    alter table public.moradores add column missao smallint not null default 0;
    -- quem já jogava não precisa da missão
    update public.moradores set missao = 2 where xp > 0 or nivel > 1;
  end if;
end $$;

create or replace function public.missao_passo(p_passo integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; bonus integer := 0;
begin
  m := _eu();
  if p_passo = 1 then
    if m.missao <> 0 then raise exception 'Essa missão já foi feita.'; end if;
    if m.xp <= 0 then raise exception 'Faça uma tarefa de trabalho primeiro.'; end if;
    bonus := 50;
    update moradores set dinheiro = dinheiro + bonus, missao = 1 where id = m.id;
  else
    if m.missao >= 2 then raise exception 'Essa missão já foi feita.'; end if;
    update moradores set missao = 2 where id = m.id;
  end if;
  return json_build_object('missao', (select missao from moradores where id = m.id), 'bonus', bonus, 'eu', _estado(m.id));
end $$;
grant execute on function public.missao_passo(integer) to authenticated;

select count(*) filter (where missao = 0) as vao_ver_a_missao, count(*) as moradores from public.moradores;
