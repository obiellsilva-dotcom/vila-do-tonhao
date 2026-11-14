-- As casas 35 e 106 ficaram escondidas no mapa novo (2.5D) e os donos não conseguiam vê-las.
-- Passa cada dono para a casa vizinha visível, de mesmo preço, sem cobrar nada.
update public.vagas set morador = null, carro = null, desde = null where casa in (35, 106);
update public.casas set dono = (select dono from public.casas where id = 35), comprada_em = now(), aberta = false where id = 31 and dono is null;
update public.moradores set casa_id = 31 where casa_id = 35;
update public.casas set dono = null, comprada_em = null, aberta = false where id = 35;
update public.casas set dono = (select dono from public.casas where id = 106), comprada_em = now(), aberta = false where id = 107 and dono is null;
update public.moradores set casa_id = 107 where casa_id = 106;
update public.casas set dono = null, comprada_em = null, aberta = false where id = 106;
select id, dono from public.casas where id in (31, 35, 106, 107);
