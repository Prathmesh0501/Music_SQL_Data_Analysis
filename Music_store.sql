

use project_db;
show tables;


-- BASIC LEVEL

-- most senior employee based on job title

SELECT first_name,last_name
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- countries that have the most invoices

SELECT billing_country, COUNT(*) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;

-- top 3 invoice totals

SELECT invoice_id,customer_id,billing_city,total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- city with the highest total invoice amount

SELECT billing_city, SUM(total) AS total_amount
FROM invoice
GROUP BY billing_city
ORDER BY total_amount DESC
LIMIT 1;

-- customer who has spent the most money

SELECT c.customer_id, c.first_name, 
c.last_name, SUM(i.total) AS total_spent
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;


-- MODERATE LEVEL

-- email, first name, and last name of customers who listen to Rock music

SELECT DISTINCT c.email, c.first_name, c.last_name
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
JOIN Invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN Genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock';


-- top 10 Rock artists based on track count

SELECT ar.name AS artist_name, 
COUNT(t.track_id) AS rock_track_count
FROM Artist ar
JOIN Album al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN Genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.name
ORDER BY rock_track_count DESC
LIMIT 10;


-- track names longer than the average track length

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) FROM track
);


-- ADVANCE LEVEL

-- how much each customer has spent on each artist

WITH artist_revenue AS (
    SELECT 
        il.invoice_id,
        t.track_id,
        al.artist_id,
        il.unit_price * il.quantity AS revenue
    FROM Invoice_line il
    JOIN track t ON il.track_id = t.track_id
    JOIN Album a ON t.album_id = a.album_id
    JOIN Artist al ON a.artist_id = al.artist_id
),
customer_artist_spending AS (
    SELECT 
        i.customer_id,
        ar.artist_id,
        SUM(ar.revenue) AS total_spent
    FROM artist_revenue ar
    JOIN Invoice i ON ar.invoice_id = i.invoice_id
    GROUP BY i.customer_id, ar.artist_id
)
SELECT 
    c.first_name, 
    c.last_name, 
    a.name AS artist_name, 
    cas.total_spent
FROM customer_artist_spending cas
JOIN Customer c ON cas.customer_id = c.customer_id
JOIN Artist a ON cas.artist_id = a.artist_id
ORDER BY cas.total_spent DESC;

-- most popular music genre for each country

WITH genre_sales AS (
    SELECT 
        c.country,
        g.name AS genre_name,
        COUNT(il.invoice_line_id) AS purchase_count
    FROM Customer c
    JOIN Invoice i ON c.customer_id = i.customer_id
    JOIN Invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN Genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
),
ranked_genres AS (
    SELECT *,
           RANK() OVER (PARTITION BY country ORDER BY purchase_count DESC) AS ranks
    FROM genre_sales
)
SELECT country, genre_name, purchase_count
FROM ranked_genres
WHERE ranks = 1
ORDER BY country;

-- top-spending customer for each country

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country,
        SUM(i.total) AS total_spent
    FROM Customer c
    JOIN Invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
),
ranked_customers AS (
    SELECT *,
           RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS ranks
    FROM customer_spending
)
SELECT country, first_name, last_name, total_spent
FROM ranked_customers
WHERE ranks = 1
ORDER BY country;





