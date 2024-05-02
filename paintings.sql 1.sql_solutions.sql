select * from [dbo].[artist]
select * from [dbo].[canvas_size]
select * from [dbo].[image_link]
select * from [dbo].[museum]
select * from [dbo].[museum_hours]
select * from [dbo].[subject]
select * from [dbo].[product_size]
select * from [dbo].[work]



--1. Fetch all the paintings which are not displayed on any museums?

select * 
from work
where museum_id is null

--2.Are there museums without any paintings ?

-- Menthod 1

select * 
from [dbo].[museum]
where [museum_id] not in 
(select distinct  museum_id
from work
where  museum_id is not null)

-- Menthod 2

select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id)

--Menthod 3

select distinct [dbo].[museum].[museum_id],[dbo].[museum].[name]
from [dbo].[museum]
where [dbo].[museum].museum_id not in (select [dbo].[work].museum_id from [dbo].[work])


--3.How many paintings have an asking price of more than their regular price ?

-- Menthod 1

select * from product_size
	where sale_price > regular_price;


--4. Identify the paintings whose asking price is less than 50% of its regular price

--Mrnthod 1

select * 
from (select * ,(diffice_price * 100)/regular_price as pencentage
from (select *,regular_price-sale_price  as diffice_price 
from product_size) as sq) as sq
where pencentage >=50

--Menthod 2 

select * 
	from product_size
	where sale_price < (regular_price*0.5);


--Menthod 3
select [dbo].[work].name,[dbo].[work].[style],[dbo].[product_size].regular_price,[product_size].sale_price
from [dbo].[work]
join [dbo].[product_size] on [dbo].[product_size].work_id=[dbo].[work].work_id
where [regular_price]/2 > [sale_price]
	
--5. Which canva size costs the most?


--Menthod 1
select top 1 *
from [dbo].[product_size]
order by [sale_price] desc

--Menthod 2

select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id=ps.size_id
	where ps.rnk=1;		
	

--Menthod 3
select top 1 *,max([dbo].[product_size].[sale_price]) as saleprice
from [dbo].[canvas_size]
join [dbo].[product_size] on [dbo].[product_size].size_id=[dbo].[canvas_size].size_id
group by [dbo].[canvas_size].size_id,dbo.canvas_size.width,dbo.canvas_size.height,dbo.canvas_size.label,dbo.product_size.work_id,dbo.product_size.size_id,dbo.product_size.sale_price,dbo.product_size.regular_price
order by max([dbo].[product_size].[sale_price]) desc


--6.Identify the museums with invalid city information in the given dataset

--Menthod 1 

select * from museum 
	where city like '[0-9]%'


--7. Fetch the top 10 most famous painting subject

--Menthod-1

select  top 10 subject ,count(subject) As no_of_painting
from [dbo].[subject]
group by subject
order by no_of_painting 

--Menthod-2

select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;


--8. Identify the museums which are open on both Sunday and Monday. Display museum name, city.

--Menthod 1

select distinct MH.museum_id,M.name,M.city,MH.day
from  [dbo].[museum] M
join  [dbo].[museum_hours] MH on M.museum_id = MH.museum_id
where MH.day = 'Sunday' 
and exists (select * from [museum_hours] MH2
            where MH.museum_id=MH2.museum_id And MH2.day = 'Monday')


--Menthod 2

select museum_id,[name],[address],[city],[state],[country],[phone]
from(
select [dbo].[museum].museum_id,[name],[address],[city],[state],[country],[phone],row_number()  over(partition by [dbo].[museum].museum_id order by [dbo].[museum].museum_id) as days
from [dbo].[museum]
join [dbo].[museum_hours] on [dbo].[museum_hours].museum_id=[dbo].[museum].museum_id
where day = 'sunday' or day='monday') sq
where days = 2


--9. How many museums are open every single day?

--Menthod 1

select Count(museum_id) as museums
from(
select [dbo].[museum].museum_id,[name],[address],[city],[state],[country],[phone],row_number()  over(partition by [dbo].[museum].museum_id order by [dbo].[museum].museum_id) as days
from [dbo].[museum]
join [dbo].[museum_hours] on [dbo].[museum_hours].museum_id=[dbo].[museum].museum_id)as sq
where days = 7

-- Menthod 2

SELECT COUNT(1)
FROM (
    SELECT museum_id as Museum, COUNT(1) AS day_count
    FROM museum_hours
    GROUP BY museum_id
    HAVING COUNT(1) = 7
) AS x;

--10. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)


--Menthod 1

select top 5 M.name, M.city,W.museum_id,Count(W.work_id) as no_of_paintings
from [dbo].[work] W
join museum M on M.museum_id = W.museum_id
where W.museum_id is not null
group by W.museum_id,M.name, M.city
order by no_of_paintings desc

--Menthod 2

select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;

--11. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)


select top 5 A.full_name,W.artist_id,Count(W.artist_id) as no_of_painting
from [dbo].[work] W
join  [dbo].[artist] A on A.artist_id = W.artist_id
group by W.artist_id,A.full_name
order by no_of_painting desc

--12. Display the 3 least popular canva sizes

--Menthod 1

select * 
from
(select  C.label,C.height,C.width,P.size_id,count(P.size_id) As no_of_use,dense_rank() over(order by count(P.[work_id])) as rank
from [dbo].[product_size] P
join  [dbo].[canvas_size] C on  C.size_id = P.size_id
group by P.size_id ,C.label,C.height,C.width) as sq
where rank <= 3

--Menthod 2 

select * 
from
(select  C.label,C.height,C.width,P.size_id,count(P.size_id) As no_of_use,dense_rank() over(order by count(P.[work_id])) as rank
from [dbo].[product_size] P
join  [dbo].[canvas_size] C on  C.size_id = P.size_id
where P.size_id is not null
group by P.size_id ,C.label,C.height,C.width) as sq
where rank <= 3

--Menthod 3

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id::text = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;



--13. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

-- Menthod 1

SELECT top 1 M.name,M.state,MH.day, DATEDIFF(MINUTE,MH.[open],MH.[close]) as Hour , MH.[open], MH.[close]
FROM [dbo].[museum_hours] MH
join [dbo].[museum] M on  MH.museum_id = M.museum_id
order by Hour  desc

-- Menthod 2
SELECT museum_name, state AS city, day, [open], [close], duration
FROM (
    SELECT m.name AS museum_name, m.state, day, [open], [close],
           CONVERT(time, [open]) AS open_time,
           CONVERT(time, [close]) AS close_time,
           DATEDIFF(MINUTE, CONVERT(time, [open]), CONVERT(time, [close])) AS duration,
           RANK() OVER (ORDER BY DATEDIFF(MINUTE, CONVERT(time, [open]), CONVERT(time, [close])) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
) x
WHERE x.rnk = 1;



--14. Which museum has the most no of most popular painting style?

--Menthod 1

select top 1 M.name, W.style, Count(W.style) as no_of_painting
from [dbo].[work] W
join [dbo].[museum] M on M.museum_id = W.museum_id
group by style,M.name
order by no_of_painting desc

--Menthod 2

with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


--15. Display the country and the city with most no of museums. Output 2 seperate 
--columns to mention the city and country. If there are multiple value, seperate them with comma

--Menthod 1

select STRING_AGG(Country, ', ') as total_Country ,STRING_AGG(city, ', ') as total_city
from
(select Country ,Count(Country) as Total_Country,city,Count(Country) as Toatl_City,dense_rank() over(order by Count(Country) desc) As rank
from [dbo].[museum]
group by Country,City
) as sq
where rank = 1

--16. Identify the artist and the museum where the most expensive and least expensive 
--painting is placed. Display the artist name, sale_price, painting name, museum name, museum city and canvas label

--Menthod 1

select  sale_price ,painting,museum_name,label,city from 
(select A.full_name,dense_rank() over(order by P.sale_price desc) as Most_Expensive ,
dense_rank () over (order by P.sale_price) as Least_Expensive,W.name as painting,M.name as museum_name,M.city,C.label ,P.sale_price
from [dbo].[product_size] P
join [dbo].[work] W  on W.work_id = P.work_id
join [dbo].[artist] A on A.artist_id = W.artist_id
join [dbo].[museum] M on M.museum_id = W.museum_id
join [dbo].[canvas_size] C on C.size_id = P.size_id)sq
where Most_Expensive = 1 or Least_Expensive = 1

--17. Which country has the 5th highest no of paintings?

--Menthod 1

select * from
(select Count(W.museum_id) as no_of_painting,M.country,rank() over(order by Count(W.museum_id)desc) as rank
from [dbo].[work] W
join [dbo].[museum] M on M.museum_id = W.museum_id
group by  M.country) as sq
where rank = 5

--Menthod 2
with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;

--18. Which are the 3 most popular and 3 least popular painting styles?

--Menthod 1

select style ,no_of_paininting,leat_popular as rank 
from
(select style,Count(style)as no_of_paininting,dense_rank() over(order by Count(style) ) as leat_popular, dense_rank() over(order by Count(style) desc ) as most_popular
from  [dbo].[work]
where style is not null
group by  style)as sq
where leat_popular <= 3 or  most_popular <= 3

--Menthod 2

with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

--19. Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality

--Menthod 1

select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	

--20. Identify the artists whose paintings are displayed in multiple countries

--menthod 1

select distinct [full_name],count([dbo].[museum].country) as total_count
from [dbo].[artist]
left join [dbo].[work] on [dbo].[work].artist_id=[dbo].[artist].artist_id
left join [dbo].[museum] on [dbo].[museum].museum_id=[dbo].[work].museum_id
group by [full_name],[dbo].[museum].name
order by count([dbo].[museum].country) desc