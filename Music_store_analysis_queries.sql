use music_store_db;

-- 1. Who is the senior most employee based on job title?

SELECT * FROM employee
ORDER BY levels desc
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT billing_country,count(*) as 'Total_invoices' FROM invoice
group by billing_country
order by Total_invoices desc
limit 10;

-- 3. What are top 3 values of total invoice?
SELECT total from invoice
order by total desc
limit 3;

-- 4.We would like to throw a promotional Music 
-- Festival in the city we made the most money. Write a query that returns one city that 
-- has the highest sum of invoice totals. Return both the city name & sum of all invoice 
-- totals

select billing_city,sum(total) as'sum' from invoice
group by billing_city
order by sum desc 
limit 1;

-- 5. Who is the best customer? The customer who has spent the most money will be 
-- declared the best customer. Write a query that returns the person who has spent the 
-- most money

select customer_id,first_name,last_name from customer 
where customer_id = (select customer_id from invoice
                     group by customer_id
                     order by sum(total) desc
                     limit 1);
                     
-- ALTERNATE METHOD
		
select c.customer_id,first_name,last_name,sum(i.total) as 'total_money_spent' from customer c
join invoice i
on c.customer_id = i.customer_id
group by first_name,last_name,c.customer_id
order by total_money_spent desc
limit 1;

-- MEDIUM QUESTIONS

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music 
-- listeners. Return your list ordered alphabetically by email starting with A

select email,first_name,last_name 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice_line.invoice_id = invoice.invoice_id
where track_id in (
                    select track_id from track
                    join genre on track.genre_id = genre.genre_id
                    where genre.name = 'Rock')
order by email;

-- 2. Let's invite the artists who have written the most rock music in our dataset. Write a 
-- query that returns the Artist name and total track count of the top 10 rock bands
 select ar.name, count(*) as 'cnt' from artist ar
 join album on ar.artist_id = album.artist_id
join track on track.album_id = album.ï»¿album_id
 where album.ï»¿album_id in( select track.album_id from track
						join genre on track.genre_id = genre.genre_id
                        where genre.name = 'Rock')
group by ar.artist_id,ar.name
order by cnt desc;

-- ALTERNATE METHOD

select ar.name, count(*) as 'cnt' from artist ar
join album on ar.artist_id = album.artist_id
join track on track.album_id = album.ï»¿album_id
join genre on track.genre_id = genre.genre_id
where genre.name = 'Rock'
group by ar.artist_id,ar.name
order by cnt desc;

-- 3. Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the 
-- longest songs listed first

select name,milliseconds from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

-- ADVANCE QUESTIONS

-- Find how much amount spent by each customer on artists? Write a query to return
-- customer name, artist name and total spent
                     
WITH best_selling_artist as (select artist.artist_id as artist_id , artist.name as artist_name,
sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
from invoice_line
join track on track.track_id = invoice_line.track_id
join album on  album.ï»¿album_id = track.album_id 
join artist on artist.artist_id = album.artist_id
group by 1,2
order by 3 desc
limit 1
)

SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.ï»¿album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- 2.We want to find out the most popular music Genre for each country. We determine the 
-- most popular genre as the genre with the highest amount of purchases. Write a query 
-- that returns each country along with the top Genre. For countries where the maximum 
-- number of purchases is shared return all Genres

with popular_genre as (select c.country,g.name, count(il.quantity) as 'purchases_per_genre',
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
 from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on t.track_id = il.track_id
join genre g on g.genre_id = t.genre_id
group by c.country,g.name
order by c.country asc , 3 desc)
select * from popular_genre where RowNo <=1;
                     
-- ALTERNATE

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


-- 3. Write a query that determines the customer that has spent the most on music for each 
-- country. Write a query that returns the country along with the top customer and how
-- much they spent. For countries where the top amount spent is shared, provide all 
-- customers who spent this amount

with most_spent_customers as (select c.first_name,c.country,sum(i.total) as 'amt_spent',
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY sum(i.total) DESC) AS RowNo
 from customer c
join invoice i on c.customer_id = i.customer_id
group by 1,2
order by c.country asc )
select * from most_spent_customers  where RowNo <=1;
                     
