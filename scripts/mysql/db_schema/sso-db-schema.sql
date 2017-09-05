CREATE DATABASE mydan_sso
  DEFAULT CHARACTER SET utf8
  DEFAULT COLLATE utf8_general_ci;
USE mydan_sso;
SET NAMES utf8;

DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user`(
  `id` int(64) NOT NULL auto_increment,
  `time`    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `username`    VARCHAR(32),
  `password` VARCHAR(64),
   PRIMARY KEY  (`id`),
   UNIQUE KEY `username` (`username`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `info`;
CREATE TABLE IF NOT EXISTS `info`(
  `id` int(64) NOT NULL auto_increment,
  `time`    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `keys`    VARCHAR(64),
  `info`    VARCHAR(64),
   PRIMARY KEY  (`id`),
   UNIQUE KEY `keys` (`keys`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `chpasswd`;
CREATE TABLE IF NOT EXISTS `chpasswd`(
  `id` int(64) NOT NULL auto_increment,
  `time`    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `usr`    VARCHAR(64),
  `key`    VARCHAR(64),
   PRIMARY KEY  (`id`),
   UNIQUE KEY `usr` (`usr`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;
