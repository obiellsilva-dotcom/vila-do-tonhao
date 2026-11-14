-- Novidades da versão 2.5D (rode pelo celular). O banco.sql completo continua valendo.
update public.trabalhos set nivel_min = 15 where id = 'policia';
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
