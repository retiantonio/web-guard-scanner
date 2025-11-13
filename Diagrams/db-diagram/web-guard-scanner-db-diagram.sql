CREATE TABLE `users` (
  `id` integer PRIMARY KEY,
  `username` varchar(255),
  `pass_hash` varchar(255),
  `email` varchar(255),
  `created_at` timestamp,
  `is_pro` bool,
  `subscription_data` timestamp
);

CREATE TABLE `subscriptions` (
  `subscription_id` integer PRIMARY KEY,
  `user_id` integer,
  `subscription_date` timestamp,
  `renewal_date` date
);

CREATE TABLE `scans` (
  `id` integer PRIMARY KEY,
  `title` varchar(255),
  `body` text COMMENT 'Content of the post',
  `user_id` integer NOT NULL,
  `status` varchar(255),
  `created_at` timestamp
);

ALTER TABLE `subscriptions` ADD FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

ALTER TABLE `scans` ADD FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
