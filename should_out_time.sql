create view checkroom
as
select a.room_num,c.reserve_time,c.should_out_time 
from tb_room a,tb_in b,tb_order c
where a.room_num=b.room_num and b.order_id=c.order_id

alter trigger checkorder
on tb_in
after insert
as
declare @should_out_time datetime
declare @reserve_time datetime
declare @order_id int
declare @room_num int
declare @temp_reserve_time datetime
declare @temp_should_time datetime
declare @temp_order int
select @order_id=order_id,@room_num=room_num
from inserted
select @reserve_time=reserve_time,@should_out_time=should_out_time from tb_order where order_id=@order_id
declare myCur CURSOR for 
select reserve_time,should_out_time
from checkroom
where room_num=@room_num
open myCur
fetch myCur into @temp_reserve_time,@temp_should_time
while(@@FETCH_STATUS=0 and @temp_reserve_time is not null and @temp_should_time is not null and (select order_id from tb_order where reserve_time=@temp_reserve_time)!=@order_id)
begin
print @temp_reserve_time
print @temp_should_time
if(datediff(day,@temp_should_time,@reserve_time)<0 or datediff(day,@temp_reserve_time,@should_out_time)>0)
begin 
delete from tb_in where order_id=@order_id
end
fetch myCur into @temp_reserve_time,@temp_should_time
end
close myCur
deallocate myCur