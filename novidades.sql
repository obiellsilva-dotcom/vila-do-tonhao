-- Novidade: o prefeito é sempre o TOP 1 do ranking. Rode no Supabase (SQL Editor).

-- O prefeito é SEMPRE o TOP 1 do ranking (mais XP). Se for ultrapassado, o novo TOP 1 assume na hora.
drop function if exists public.assumir_prefeitura();
create or replace function public._atualiza_prefeito() returns trigger
language plpgsql security definer set search_path = public as $$
declare atual uuid; top uuid;
begin
  select prefeito into atual from cidade where id = 1;
  -- em caso de empate de XP, quem já é prefeito continua
  select id into top from moradores where not banido
    order by xp desc, (id is not distinct from atual) desc, criado_em limit 1;
  if top is distinct from atual then
    update cidade set prefeito = top, desde = now() where id = 1;
  end if;
  return null;
end $$;
drop trigger if exists prefeito_top1 on public.moradores;
create trigger prefeito_top1 after insert or delete or update of xp, banido on public.moradores
  for each statement execute function public._atualiza_prefeito();
-- já coloca o TOP 1 atual no cargo
update public.cidade set prefeito = (select id from public.moradores where not banido order by xp desc, criado_em limit 1), desde = now()
  where id = 1 and prefeito is distinct from (select id from public.moradores where not banido order by xp desc, criado_em limit 1);

select m.nome as prefeito from public.cidade c left join public.moradores m on m.id = c.prefeito;
