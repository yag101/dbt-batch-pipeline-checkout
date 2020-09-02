{{ config(
  materialized='table'
) }}
--Materialises the final query as a table to improve performance for the end user

WITH
  pageviews AS (
  SELECT
    user_id,
    url,
    pageview_postcode, -- Pulling in the postcode at the time the page view was made
    pageview_extractdatetime
  FROM
    {{ ref('pageviews_enhanced') }} t0)

SELECT
  COUNT(*) AS pageviews,
  pageview_postcode,
  pageview_extractdatetime AS pageview_hour

FROM
  pageviews
GROUP BY
  pageview_postcode,
  pageview_extractdatetime
-- A count of the number of pageviews per hour, by the postcode of the user at the time the page view was made
