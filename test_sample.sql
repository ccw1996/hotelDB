insert into tb_things(things_id,things_name,things_price) values
(1000,'电视',5000.00),
(1001,'电脑',2000.00),
(1002,'电冰箱',300.20),
(1003,'洗衣机',1500.00),
(1004,'地毯',100.00),
(1005,'电话',50.00);

insert into tb_customer(customer_id,customer_name,customer_sex) values
('330311200101011997','小明','男'),
('330311200101011998','小红','女'),
('330311200101011999','大明','男'),
('330311200101012000','大红','女'),
('330311200101012001','小花','女'),
('330311200101012002','小钢','男');

insert into tb_room(room_num,room_status,room_kind,room_person,room_price) values
(101,0,'标准间',1,100.00),
(202,0,'三人间',1,150.00),
(310,0,'大床间',1,120.00),
(404,0,'豪华间',1,200.00),
(502,0,'总统间',1,300.00),
(666,0,'标准间',1,100.00);

insert into tb_roomthings(things_id,room_num)values
(1000,101),
(1001,310),
(1002,202),
(1003,404),
(1004,502),
(1005,666);

insert into tb_in(customer_id,order_id,room_num)values
('330123456789123456',121,101);

--insert into tb_order(order_id,reserve_time,should_out_time) values
--(10001,'2005-05-07','2005-06-03');

insert into tb_in(customer_id,order_id,room_num) values
('330311200101011999',10001,101);