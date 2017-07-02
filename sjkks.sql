CREATE TABLE tb_news (
  news_id int PRIMARY KEY not null,
  news_content VARCHAR(200) NOT NULL,
  news_time DATETIME not NULL 
);

create table tb_vip(
    vip_level int primary key not null,
    vip_count numeric(6,2) not null,
);

CREATE TABLE tb_customer (
  customer_id CHAR(18) PRIMARY KEY not null,
  customer_name VARCHAR(10) not null,
  customer_sex VARCHAR(5)  DEFAULT '男' not null,
  CHECK (customer_sex in('男','女')),
  customer_vip int default 1 not null
constraint vip foreign key(customer_vip) references tb_vip(vip_level)
);

CREATE TABLE tb_advice (
  advice_id int PRIMARY KEY not null,
  advice_content VARCHAR(200) NOT NULL,
  advice_time DATETIME not null
);

CREATE TABLE tb_room (
  room_num int PRIMARY KEY not NULL,
  room_status int DEFAULT 0 not null, --0为空房，1为预定，2为入住
  CHECK (room_status in(0,1,2)),
  room_kind VARCHAR(20) NOT NULL,
  room_person int not NULL,
  CHECK (room_person>0),
  room_price int not NULL ,
  CHECK (room_price>0),
  status int default 0 not null
);

CREATE TABLE tb_things (
  things_id int PRIMARY KEY NOT NULL ,
  things_name VARCHAR(20) NOT NULL ,
  things_price NUMERIC(6,2) NOT NULL ,
  CHECK (things_price>=0),
  things_kind int default 1 not null
);

CREATE TABLE tb_order (
  order_id int PRIMARY KEY NOT NULL ,
  reserve_time DATETIME DEFAULT NULL ,
  in_time DATETIME DEFAULT NULL ,
  out_time DATETIME DEFAULT NULL ,
  fee NUMERIC(6,2) DEFAULT 0 not NULL ,
  CHECK (fee>=0)
);

CREATE TABLE tb_roomthings (
  things_id int PRIMARY KEY NOT NULL ,
  room_num int NOT NULL ,
  CONSTRAINT RoomThings_things FOREIGN KEY (things_id) REFERENCES tb_things(things_id),
  CONSTRAINT RoomThings_room FOREIGN KEY (room_num)REFERENCES tb_room(room_num)
);

CREATE TABLE tb_damagethings (
  things_id int PRIMARY KEY NOT NULL ,
  order_id int NOT NULL ,
  CONSTRAINT DamageThings_things FOREIGN KEY (things_id) REFERENCES tb_things(things_id),
  CONSTRAINT DamageThings_order FOREIGN KEY (order_id)REFERENCES tb_order(order_id)
);

CREATE TABLE tb_in (
  room_num int PRIMARY KEY not null,
  customer_id char(18) PRIMARY KEY NOT NULL ,
  order_id int PRIMARY KEY NOT NULL ,
  CONSTRAINT In_room FOREIGN KEY (room_num) REFERENCES tb_room(room_num),
  CONSTRAINT In_costomer FOREIGN KEY (customer_id) REFERENCES tb_customer(customer_id),
  CONSTRAINT In_order FOREIGN KEY (order_id) REFERENCES tb_order(order_id)
);

CREATE TABLE tb_leavemsg (
  advice_id int PRIMARY KEY NOT NULL ,
  customer_id char(18) NOT NULL,
  CONSTRAINT LeaveMsg_advice FOREIGN KEY (advice_id) REFERENCES tb_advice(advice_id),
  CONSTRAINT LeaveMsg_customer FOREIGN KEY (customer_id) REFERENCES tb_customer(customer_id)
);

--损坏费用触发器

CREATE TRIGGER damagegoods
ON tb_damagethings
FOR INSERT
AS
  DECLARE @things_id INT
  DECLARE @order_id INT
  DECLARE @things_price NUMERIC(6,2)
  DECLARE @fee NUMERIC(6,2)
  SELECT @things_id=things_id,@order_id=order_id
    from inserted
  SELECT @fee=fee from tb_order where order_id=@order_id
  SELECT @things_price=things_price from tb_things where things_id=@things_id
  UPDATE tb_order SET fee=@things_price +@fee where order_id=@order_id
  UPDATE tb_things SET things_kind=0 where things_id=@things_id
  DELETE FROM tb_roomthings where things_id=@things_id

--退房时费用触发器
create TRIGGER out_free
  on tb_order
  after UPDATE
  AS
  DECLARE @order_id int
  DECLARE @in_time DATETIME
  DECLARE @out_time DATETIME
  DECLARE @fee NUMERIC(6,2)
  DECLARE @room_id int
  DECLARE @room_price NUMERIC(6,2)
  declare @customer_id char(18)
  declare @vip_level int 
  declare @vip_count numeric(6,2)
    SELECT @out_time=out_time,@order_id=order_id
    FROM tb_order
    if exists(select * from tb_order where out_time is not null)
    begin
    if((select status from tb_order where out_time=@out_time)=0)
    begin
    SELECT @in_time=in_time from tb_order where out_time=@out_time
    print @in_time
    if (@in_time is not null)
    begin
    SELECT @fee=fee from tb_order where out_time=@out_time
    SELECT @room_id=room_num from tb_in where order_id=@order_id
    select @customer_id=customer_id from tb_in where order_id=@order_id
    select @vip_level=customer_vip from tb_customer where customer_id=@customer_id
    select @vip_count=vip_count from tb_vip where vip_level=@vip_level
    SELECT @room_price=room_price from tb_room where room_num=@room_id
    UPDATE tb_order set fee =day(@out_time-@in_time-1)*@room_price*@vip_count+@fee where order_id=@order_id
    UPDATE tb_room set room_status=0 where room_num=@room_id
    update tb_order set status=1 where out_time=@out_time
    end
    else
    begin
    SELECT @fee=fee from tb_order where out_time=@out_time
    SELECT @room_id=room_num from tb_in where order_id=@order_id
    select @customer_id=customer_id from tb_in where order_id=@order_id
    select @vip_level=customer_vip from tb_customer where customer_id=@customer_id
    select @vip_count=vip_count from tb_vip where vip_level=@vip_level
    SELECT @room_price=room_price from tb_room where room_num=@room_id
    UPDATE tb_order set fee =0 where order_id=@order_id
    UPDATE tb_room set room_status=0 where room_num=@room_id
    update tb_order set status=1 where out_time=@out_time
    end
    end
    end


--存储过程

CREATE PROCEDURE getreserverecord(
  @customer_id char(18),
  @room_num    INT,
  @order_id    INT)
  AS
  BEGIN
    SELECT @room_num=room_num,@order_id=order_id from tb_in
    where customer_id=@customer_id
  END


--列举每个房间里的物品
create VIEW room_things
  AS
  SELECT b.things_id,b.things_name,b.things_price,a.room_num from tb_roomthings a,tb_things b
  where a.things_id=b.things_id
  WITH CHECK OPTION

create trigger openroom   --检查黑名单
on tb_in
after insert
as
declare @customer_id char(18)
select @customer_id=customer_id from inserted
if exists(select * from tb_customer where customer_id=@customer_id and customer_vip=0)
delete from tb_in where customer_id=@customer_id

create view customer_pay
as 
select a.customer_id,a.customer_name,a.customer_vip,sum(fee) as 总消费记录
from tb_customer a,tb_in b,tb_order c
where a.customer_id=b.customer_id and b.order_id=c.order_id
group by a.customer_id,a.customer_name,a.customer_vip
with check option

create procedure bookroom(
    @customer_id char(18),
    @order_id int,
    @reserve_time datetime,
    @room_num int)
    as
    if not exists(select * from tb_order where order_id=@order_id)
    begin
    insert into tb_order(order_id,reserve_time) values(@order_id,@reserve_time)
    insert into tb_in(customer_id,order_id,room_num) values(@customer_id,@order_id,@room_num)
    end

create procedure cancelroom(@order_id int)
    as
    declare @reserve_time datetime
    begin
    select @reserve_time=reserve_time from tb_order where order_id=@order_id
    update tb_order set out_time=@reserve_time where order_id=@order_id
    end


create trigger gotoroom
on tb_order
for update
as
declare @in_time datetime
declare @order_id int 
declare @room_num int
select @in_time=in_time from inserted
if((select out_time from tb_order where in_time=@in_time)is null)
select @order_id=order_id from tb_order where in_time=@in_time
select @room_num=room_num from tb_in where order_id=@order_id
update tb_room set room_status=2 where room_num=@room_num

create trigger inroom
on tb_in
after insert
as
declare @room_num int
declare @order_id int
select @room_num = room_num,@order_id=order_id
from inserted
if((select in_time from tb_order where order_id=@order_id)is not null)
update tb_room set room_status=2
where room_num=@room_num 

CREATE trigger orderroom
on tb_in
after insert,update
as
declare @room_num int
declare @order_id int
select @room_num = room_num,@order_id=order_id
from tb_in
if exists(select reserve_time from tb_order where order_id=@order_id and in_time is null)
update tb_room set room_status=1
where room_num=@room_num 

create table tb_getpay(
  order_id int primary key not null,
  getpay NUMERIC(6,2) default 0,
  note VARCHAR(100) DEFAULT null,
  constraint pay foreign key(order_id) references tb_order(order_id) 
)


grant select,insert,update,delete on tb_advice to customer
grant select on tb_advice to openwaiter,roomwaiter
grant select,insert,update,delete on tb_news to openwaiter
grant select,insert,update,delete on tb_customer to openwaiter
grant select on tb_damagethings to openwaiter,customer
grant select,insert,update,delete on tb_damagethings to roomwaiter
grant select,insert,update,delete on tb_getpay to openwaiter
grant select,insert,update,delete on tb_in to openwaiter
grant select,insert,update,delete on tb_order to openwaiter
grant select,insert,update,delete on tb_room to roomwaiter
grant select on tb_room to customer,openwaiter
grant select,insert,update,delete on tb_roomthings to roomwaiter
grant select,insert,update,delete on tb_things to roomwaiter
grant select on tb_things to openwaiter,customer