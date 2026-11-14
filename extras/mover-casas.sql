-- As casas 35 e 106 ficaram escondidas no mapa 2.5D. Passa cada dono para a casa vizinha visível (mesmo preço), sem cobrar.
do $$
declare d uuid;
begin
  select dono into d from public.casas where id = 35;
  if d is not null then
    update public.vagas set morador = null, carro = null, desde = null where casa = 35;
    update public.casas set dono = null, comprada_em = null, aberta = false where id = 35;
    update public.casas set dono = d, comprada_em = now(), aberta = false where id = 31 and dono is null;
    update public.moradores set casa_id = 31 where id = d;
  end if;
  select dono into d from public.casas where id = 106;
  if d is not null then
    update public.vagas set morador = null, carro = null, desde = null where casa = 106;
    update public.casas set dono = null, comprada_em = null, aberta = false where id = 106;
    update public.casas set dono = d, comprada_em = now(), aberta = false where id = 107 and dono is null;
    update public.moradores set casa_id = 107 where id = d;
  end if;
end $$;
select c.id, m.nome from public.casas c left join public.moradores m on m.id = c.dono where c.id in (31, 35, 106, 107);
