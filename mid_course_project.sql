-- THE OBJECTIVES (FIRST 8 MONTHS) : 
USE mavenfuzzyfactory;

-- QUESTION 1 : Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders so that we can showcase the growth there?

SELECT 
    MONTH(DATE(ws.created_at)) as Month,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/ COUNT(DISTINCT ws.website_session_id) AS CVR
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(ws.created_at));




-- QUESTION 2 : Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell.

SELECT 
    MONTH(DATE(ws.created_at)) as Month,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(ws.created_at));


-- QUESTION 3 : While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.

SELECT 
    MONTH(DATE(ws.created_at)) as Month,
    device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-11-27'
    AND utm_campaign = 'nonbrand'
    AND utm_source = 'gsearch'
GROUP BY MONTH(DATE(ws.created_at)),utm_campaign,device_type;

-- other solution 

SELECT
	YEAR(website_sessions.created_at) AS yr, 
    MONTH(website_sessions.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders 
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1,2;



-- QUESTION 4 : I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?

SELECT
	YEAR(website_sessions.created_at) AS yr, 
    MONTH(website_sessions.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions
	LEFT JOIN orders 
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

-- organic = only referer
-- paid = source + referers
-- direct no source + no referer


-- QUESTION 5 : I’d like to tell the story of our website performance improvements over the course of the first 8 months. Could you pull session to order conversion rates, by month?

SELECT 
    MONTH(DATE(wp.created_at)) AS Month,
    COUNT(DISTINCT wp.website_session_id) AS session,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT wp.website_session_id) AS session_to_order_CVR
FROM
    website_pageviews wp
        LEFT JOIN
    orders o ON wp.website_session_id = o.website_session_id
WHERE
    wp.created_at < '2012-11-27'
GROUP BY MONTH(DATE(wp.created_at));

-- QUESTION 6 : For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value)

SELECT 
    COUNT(DISTINCT data_1.website_session_id) AS sessions,
    data_1.pageview_url,
    COUNT(order_id) AS orders,
     COUNT(order_id)/COUNT(DISTINCT data_1.website_session_id) AS cvr,
    SUM(price_usd) AS revenue
FROM 
(
SELECT
	wp.created_at,
	wp.website_session_id,
    pageview_url
FROM 
	website_pageviews wp 
LEFT JOIN 
	website_sessions ws ON wp.website_session_id = ws.website_session_id
WHERE 
	utm_campaign = 'nonbrand'
	AND wp.created_at > '2012-06-19' 
    AND wp.created_at < '2012-07-28'
    AND utm_source = 'gsearch'
    AND pageview_url IN ('/lander-1','/home') ) AS data_1 
LEFT JOIN orders o ON data_1.website_session_id = o.website_session_id
GROUP BY 
    data_1.pageview_url;



-- QUESTION 7 : For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).


-- first session id 11683 and first day = 2012-06-19 
SELECT 
	MIN(wp.website_session_id),
    wp.created_at
FROM 
	website_pageviews wp 
WHERE pageview_url = '/lander-1';


-- Looking for the different step of conversion funnel 
SELECT DISTINCT( pageview_url) FROM website_pageviews 
WHERE created_at > '2012-06-19'
	AND created_at < '2012-07-28';
    


-- Creating temporary table to look for value 
CREATE TEMPORARY TABLE flagged_steps    
SELECT 
	website_session_id,
    MAX(homepage) AS to_homepage,
    MAX(custom_lander) AS to_customer_lander,
    MAX(products_flag) AS to_product,
    MAX(mrfuzzy_flag) AS to_mrfuzzy,
    MAX(cart_flag) AS to_cart,
    MAX(shipping_flag) AS to_shipping,
    MAX(billing_flag) AS to_billing,
    MAX(thankyou_flag) AS to_thankyou
FROM (
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    wp.created_at,
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander
    ,CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END as products_flag
    ,CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_flag
    ,CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_flag
    ,CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_flag
    ,CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_flag
    ,CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_flag
FROM 
	website_sessions ws 
LEFT JOIN 
	website_pageviews wp 
	ON ws.website_session_id = wp.website_session_id
WHERE 
	utm_campaign = 'nonbrand'
	AND wp.created_at > '2012-06-19' 
    AND wp.created_at < '2012-07-28'
    AND utm_source = 'gsearch'
) fd 
GROUP BY website_session_id;


-- Volume Version of the conversion funnel
SELECT 
    CASE WHEN to_homepage = 1 THEN 'to_homepage'
		 WHEN to_customer_lander = 1 THEN 'to_customer_lander'
         ELSE 'Missing Value' END as segment,
	COUNT(DISTINCT(website_session_id)) AS sessions,
    COUNT(DISTINCT( CASE WHEN to_product = 1 THEN website_session_id ELSE NULL END)) as to_product,
	COUNT(DISTINCT( CASE WHEN to_mrfuzzy = 1 THEN website_session_id ELSE NULL END)) as to_mrfuzzy,
    COUNT(DISTINCT( CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END)) as to_cart,
    COUNT(DISTINCT( CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END)) as to_shipping,
    COUNT(DISTINCT( CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END)) as to_billing,
    COUNT(DISTINCT( CASE WHEN to_thankyou = 1 THEN website_session_id ELSE NULL END)) as to_thankyou
FROM flagged_steps
GROUP BY 1;


-- Rate version of the conversion funnel
SELECT 
	CASE WHEN to_homepage = 1 THEN 'to_homepage'
			 WHEN to_customer_lander = 1 THEN 'to_customer_lander'
			 ELSE 'Missing Value' END as segment,
	COUNT(DISTINCT(website_session_id)) AS sessions,
    COUNT(DISTINCT( CASE WHEN to_product = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT(website_session_id)) as to_product_rate,
	COUNT(DISTINCT( CASE WHEN to_mrfuzzy = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT( CASE WHEN to_product = 1 THEN website_session_id ELSE NULL END)) as to_mrfuzzy_rate,
    COUNT(DISTINCT( CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT( CASE WHEN to_mrfuzzy = 1 THEN website_session_id ELSE NULL END)) as to_cart_rate,
    COUNT(DISTINCT( CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT( CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END)) as to_shipping_rate,
    COUNT(DISTINCT( CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT( CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END)) as to_billing_rate,
    COUNT(DISTINCT( CASE WHEN to_thankyou = 1 THEN website_session_id ELSE NULL END))/COUNT(DISTINCT( CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END)) as to_thankyou_rate
FROM flagged_steps
GROUP BY 1;





-- QUESTION 8 : I’d love for you to quantify the impact of our billing test, as well. 
-- Please analyze the lift generated from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand monthly impact.

-- first step checking for the different version of the billing page url

SELECT 
COUNT(DISTINCT website_session_id) as sessions,
pageview_url 
FROM 
	website_pageviews
WHERE 
	pageview_url IN ('/billing','/billing-2')
	AND created_at > '2012-09-10'
    AND created_at < '2012-11-10'
GROUP BY pageview_url;

-- Basically this a 2 months period, thus I'll do a comparison with the previous two months period (2012-07-10) - (2012-09-09) 
-- I will compare the revenue per billing page before the test and after the test and I will aggregate both billing pages revenue to obtain a proper result

SELECT 	
	COUNT(DISTINCT website_session_id) as sessions,
	pageview_url
FROM 
	website_pageviews
WHERE 
	created_at > '2012-07-10'
    AND created_at < '2012-09-09'
GROUP BY pageview_url;

-- We went from 920 billing session to approximately 1k4 billing sessions two months later

SELECT 
	-- wp.website_session_id, 
    pageview_url,
   -- order_id, 
    SUM(price_usd) AS revenue
FROM
	website_pageviews wp 
LEFT JOIN orders o ON wp.website_session_id = o.website_session_id
WHERE pageview_url IN ('/billing','/billing-2')
	AND wp.created_at > '2012-09-10'
    AND wp.created_at < '2012-11-10'
GROUP BY 1;
-- HAVING order_id IS NOT NULL;
-- Revenue for the two testing months : 
-- /billing-2	20 495.90
-- /billing	    14 997.00

-- COMPARISON WITH THE PAST TWO MONTHS 

SELECT 
	-- wp.website_session_id, 
    pageview_url,
   -- order_id, 
    SUM(price_usd) AS revenue
FROM
	website_pageviews wp 
LEFT JOIN orders o ON wp.website_session_id = o.website_session_id
WHERE pageview_url IN ('/billing','/billing-2')
	AND wp.created_at > '2012-07-10'
    AND wp.created_at < '2012-9-10'
GROUP BY 1;

-- Revenue for the two months before : 
-- /billing	21 195.76

SELECT
	billing_version_seen, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
 FROM( 
SELECT 
	website_pageviews.website_session_id, 
    website_pageviews.pageview_url AS billing_version_seen, 
    orders.order_id, 
    orders.price_usd
FROM website_pageviews 
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at > '2012-09-10' -- prescribed in assignment
	AND website_pageviews.created_at < '2012-11-10' -- prescribed in assignment
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1
;

-- Revenue per billing page 
	



