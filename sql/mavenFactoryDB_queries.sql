##############################################################
## VIEW FOR CONVERSION RATE PER UTM_SOURCE AND UTM_COMPAIGN ##
##############################################################
CREATE VIEW utm_cvr AS
SELECT
    website_sessions.utm_source,
    website_sessions.utm_campaign,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    (COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id))*100 CVR_Percentage
FROM website_sessions LEFT JOIN orders on website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.utm_source IS NOT null
GROUP BY 1,2
ORDER BY 5 DESC;

##############################################################
##### VIEW FOR UTM_SOURCE CONVERSION RATE PER YEAR_MONTH #####
##############################################################
CREATE VIEW cvr_per_source_date AS
SELECT
website_sessions.utm_source as utm_source,
YEAR(website_sessions.created_at) as year,
MONTH(website_sessions.created_at) as month,
COUNT(DISTINCT website_sessions.website_session_id) as sessions,
COUNT(DISTINCT orders.order_id) as orders,
COUNT(DISTINCT orders.order_id)/count(DISTINCT website_sessions.website_session_id) as cvr
FROM website_sessions LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.utm_source IS NOT null
GROUP BY 1, 2, 3;

##############################################################
########## VIEW FOR PAGES WITH MOST SESSIONS NUMBER ##########
##############################################################
CREATE VIEW most_visisted_pages AS
SELECT
pageview_url,
COUNT(DISTINCT website_session_id) as sessions
FROM website_pageviews
GROUP BY pageview_url
ORDER BY sessions DESC;

##############################################################
## VIEW FOR CONVERSION RATE PER DEVICE (MOBILE OR DESKTOP) ###
##############################################################
CREATE VIEW cvr_per_device AS
SELECT
    website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    (COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id))*100 CVR_Percentage
FROM website_sessions LEFT JOIN orders on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source is not null
GROUP BY 1
ORDER BY 4 DESC;

##############################################################
## VIEW FOR CONVERSION RATE AND REVENUE PER YEAR_QUARTER #####
##############################################################
CREATE VIEW qtr_cvr_revenue AS
SELECT
YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_CVR,
    ROUND(SUM(price_usd)/COUNT(DISTINCT orders.order_id),2) AS revenue_per_order,
    ROUND(SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id),2) AS revenue_per_session
FROM
    website_sessions LEFT JOIN orders ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

##############################################################
## VIEW FOR THE 4 PRODUCTS REVENUE PERCENTAGE PER YEAR_MONTH #
##############################################################
CREATE VIEW products_revenue_percentage AS 
SELECT 
    YEAR(created_at) AS yr, 
    MONTH(created_at) AS mo, 
    (SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END))/SUM(price_usd)*(100) AS mrfuzzy_rev_percentage, 
    (SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END))/SUM(price_usd)*(100) AS lovebear_rev_percentage, 
    (SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END))/SUM(price_usd)*(100) AS birthdaybear_rev_percentage, 
    (SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END))/SUM(price_usd)*(100) AS minibear_rev_percentage, 
    SUM(price_usd) AS total_revenue, 
    SUM(price_usd - cogs_usd) AS total_margin 
FROM order_items 
GROUP BY 1,2 
ORDER BY 1,2;

##############################################################
######## VIEW FOR THE 4 PRODUCTS REVENUE PER YEAR_MONTH ######
##############################################################
CREATE VIEW products_revenue AS
SELECT 
    YEAR(created_at) AS yr, 
    MONTH(created_at) AS mo,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev, 
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev, 
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev, 
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev, 
    SUM(price_usd) AS total_revenue, 
    SUM(price_usd - cogs_usd) AS total_margin 
FROM order_items 
GROUP BY 1,2 
ORDER BY 1,2;

##############################################################
######## VIEW FOR THE 4 PRODUCTS REVENUE PER YEAR ############
##############################################################
CREATE VIEW products_revenue_by_year AS
SELECT 
    yr, mrfuzzy_rev, lovebear_rev, 
    birthdaybear_rev, minibear_rev, 
    total_revenue, total_margin 
FROM ( 
    SELECT 
        YEAR(created_at) AS yr, 
        SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev, 
        SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev, 
        SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev, 
        SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev, 
        SUM(price_usd) AS total_revenue, SUM(price_usd - cogs_usd) AS total_margin 
    FROM order_items 
    GROUP BY 1 
    ORDER BY 1 )
    AS revenue_by_product;

##############################################################
######## VIEW FOR THE 4 PRODUCTS REFUND PERCENTAGE ###########
##############################################################
CREATE VIEW most_returened_products AS
SELECT 
    p.product_name, 
    COUNT(oir.order_item_refund_id) as refund_num,
    COUNT(oi.order_item_id) as sell_num,
    (COUNT(oir.order_item_refund_id)/Count(oi.order_item_id))*100 as percentage
from order_item_refunds oir RIGHT JOIN order_items oi ON
        oir.order_item_id = oi.order_item_id INNER JOIN products p ON 
        oi.product_id = p.product_id
GROUP BY p.product_id
ORDER BY percentage DESC;

##############################################################
##### VIEW FOR #BUYERS AT FIRST VISIT VS AT LATER VISITS #####
##############################################################
CREATE VIEW first_visit_buy AS
SELECT 
    SUM(CASE WHEN ws.is_repeat_session = 0 THEN 1 ELSE 0 END) AS first_visit_buyers, 
    SUM(CASE WHEN ws.is_repeat_session = 1 THEN 1 ELSE 0 END) AS second_visit_buyers 
FROM website_sessions AS ws JOIN orders AS o ON ws.website_session_id = o.website_session_id;

##############################################################
############# VIEW FOR NEW USERS PER YEAR_MONTH ##############
##############################################################
CREATE VIEW new_users_per_month_year AS
SELECT 
    YEAR(created_at) AS yr, 
    MONTH(created_at) AS mo,
    COUNT(DISTINCT user_id) AS NEW_users
FROM `website_sessions`
WHERE is_repeat_session =1
GROUP BY 1,2;

#################################################################################
##VIEW FOR #SESSSIONS PER PAGES ON PATH TO BUY MrFUZZY (EACH PAGE AND COMBINED)##
#################################################################################
CREATE VIEW path_to_buy_MrFuzzy AS
SELECT 
year, month,
    COUNT(sessions),
    SUM(CASE WHEN Find_In_Set('/products',page_path)>0 THEN 1 ELSE 0 END) as product_page,
    SUM(CASE WHEN Find_In_Set('/the-original-mr-fuzzy',page_path)>0 THEN 1 ELSE 0 END) as MrFuzzy_page,
    SUM(CASE WHEN Find_In_Set('/cart',page_path) THEN 1 ELSE 0 END) AS cart_page,
    SUM(CASE WHEN Find_In_Set('/cart',page_path) AND Find_In_Set('/the-original-mr-fuzzy',page_path)>0 AND      Find_In_Set('/cart',page_path) THEN 1 ELSE 0 END) AS full_path
FROM(
	SELECT 
        website_session_id AS sessions,
        YEAR(website_pageviews.created_at) as year,
        MONTH(website_pageviews.created_at) as month,
        GROUP_CONCAT(pageview_url) as page_path
   FROM website_pageviews
   GROUP BY website_session_id) as table1
GROUP BY 1,2;

##############################################################
## VIEW FOR MAXIMUM DAYS BETWEEN CONSECUTIVE ORDERS PER USER #
##############################################################
CREATE VIEW max_days_bw_seq_orders AS
SELECT 
    user_id, 
    MAX(diff) days_bt_orders
FROM ( 
    SELECT 
        x.user_id, 
        DATEDIFF(MIN(y.created_at),x.created_at) diff
    FROM orders x JOIN orders y ON y.user_id = x.user_id AND y.created_at > x.created_at 
    GROUP BY x.user_id, x.created_at) z            
GROUP BY user_id;

##############################################################
### VIEW FOR #USERS WHO RETURNED ONCE, TWICE OR THREE TIMES ##
##############################################################
CREATE VIEW total_users_per_refundnum AS
SELECT 
    refund_num,
    COUNT(refund_num) AS total_users
FROM (
	SELECT 
        orders.user_id AS users,
        COUNT(order_item_refunds.order_id) AS refund_num
	FROM orders LEFT JOIN order_item_refunds ON order_item_refunds.order_id = orders.order_id 
	GROUP BY orders.user_id) table1 
GROUP BY refund_num 
ORDER BY refund_num DESC;

###############################################################
# VIEW FOR TOP 20 SPENDING USERS WITH THE UTM_SOURCE THEY USE # 
###############################################################
# SAVED AS top_buyers.csv
SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      ' MAX(case when utm_source = ''',
      utm_source,
      ''' then 1 else 0 end) as ',utm_source
    )
  ) INTO @sql
FROM
  (SELECT DISTINCT website_sessions.utm_source FROM website_sessions) as table1;
SET @sql = CONCAT('SELECT
                        website_sessions.user_id, 
                        SUM(orders.price_usd) as total_spending, 
                        Count(website_sessions.website_session_id) as total_sessions, 
                        COUNT(orders.order_id) as total_orders, ', @sql, ' 
				  FROM website_sessions LEFT JOIN orders on website_sessions.website_session_id = orders.website_session_id
                  GROUP BY 1
                  ORDER BY total_spending DESC
                  LIMIT 20;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

##############################################################
## VIEW FOR CROSS-SELL PRODUCTS NUMBER FOR EACH PRIMARY ONE ##
##############################################################
# as the below query returned empty results, we will query for one secondary product
SELECT order_id, COUNT(*)
FROM order_items
GROUP BY order_id
HAVING COUNT(*) >= 3;

CREATE VIEW cross_sell_items AS
SELECT
    orders.order_id,
    orders.primary_product_id,
    order_items.product_id AS cross_sell_product_id
FROM orders LEFT JOIN order_items ON orders.order_id = order_items.order_id
AND order_items.is_primary_item = 0;

################################################################
# VIEW FOR CROSS-SELL PRODUCTS PERCENTAGE FOR EACH PRIMARY ONE #
################################################################
CREATE VIEW cross_sell_items_percentage AS
SELECT
    orders.primary_product_id,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    (SUM(CASE WHEN order_items.product_id=1 then 1 else 0 END)/COUNT(DISTINCT orders.order_id))*100 AS product1,
    (SUM(CASE WHEN order_items.product_id=2 then 1 else 0 END)/COUNT(DISTINCT orders.order_id))*100 AS product2,
    (SUM(CASE WHEN order_items.product_id=3 then 1 else 0 END)/COUNT(DISTINCT orders.order_id))*100 AS product3,
    (SUM(CASE WHEN order_items.product_id=4 then 1 else 0 END)/COUNT(DISTINCT orders.order_id))*100 AS product4
FROM orders LEFT JOIN order_items ON orders.order_id = order_items.order_id
AND order_items.is_primary_item = 0
GROUP BY 1

################################################################
# VIEW FOR NUMBER OF BRAND VS NONBRAND SEARCHES PER YEAR_MONTH #
################################################################
CREATE VIEW  brand_vs_nonbrand_compain AS
SELECT 
	year(created_at) AS year,
	month(created_at) AS month,
	SUM(CASE WHEN utm_campaign = 'nonbrand' THEN 1 ELSE 0 END) AS nonbrand_search,
	SUM(CASE WHEN utm_campaign = 'brand' THEN 1 ELSE 0 END) AS brand_search 
FROM `mvfactory`.`website_sessions` 
GROUP BY 1,2
