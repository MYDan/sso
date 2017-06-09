               sso 
                            单点登录SSO（Single Sign On）

使用说明：
   1. 在config.yml中把数据库信息配置上

        database: 'mydan_sso'
        host: '127.0.0.1'
        username: 'root'
        password: ''

   2. 在config.yml中添加要种的cookie的域

      set_session_domain: '.mydan.org'

      或则
 
      set_session_domain: [ '.mydan1.org', '.mydan2.org' ]

   3. 在数据库中建下面两个表
       mysql -h 127.0.0.1 -u root -p < scripts/mysql/db_schema/sso-db-schema.sql
       
       select * from info where time < date_sub(now(),interval 3 hour) ;
   
    4. 服务操作
        ./control start
        ./control stop   
        ./control restart
        ./control status
  
