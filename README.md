[中文](README.md) | [English](README_EN.md)

# docker-yapi
使用Docker容器运行Yapi（https://github.com/YMFE/yapi）

* [YAPI github](https://github.com/YMFE/yapi)
* [YAPI 官方文档](https://hellosean1025.github.io/yapi/)

| 环境 | 说明 | 测试可用 |
| --- | --- | --- |
| yapi | 仅支持1.8.5版本，已内置在镜像中 | ![yapi](https://img.shields.io/badge/yapi-1.8.5-blue.svg) |
| docker | 较高版本即可 | ![docker](https://img.shields.io/badge/docker-18.09.8-blue.svg) |
| docker-compose | 需要支持v3语法 | ![docker-compose](https://img.shields.io/badge/docker--compose-1.24.1-blue.svg) |
| node | 要求7.6+，已内置在镜像中 | ![node](https://img.shields.io/badge/node-10.18.1-blue.svg) |
| mongo | 要求2.6+ | ![mongo](https://img.shields.io/badge/mongo-3.4.24-blue.svg) |


# 1 快速开始

## 1.1 镜像相关说明
| 名称 | 说明 |
| --- | --- |
| 操作系统 | [node:10.18.1-alpine3.11](https://hub.docker.com/_/node) |
| 工作目录 | /opt/yapi |
| 日志目录 | /opt/yapi/vendors/log，docker-compose会挂载到/opt/yapi/vendors/log目录下 |
| 配置文件 | /opt/yapi/config.json，可以自行通过docker的volume进行直接挂载 |
| apk默认仓库 | https://mirrors.aliyun.com/alpine/v3.11/main |
| npm默认仓库 | https://registry.npm.taobao.org |
| 已安装软件 | bash，yapi-cli |
| 支持YAPI升级 | ✖ 后续会调试和支持 |
| 支持MongoDB集群 | ✔ |
| 支持YAPI插件 | ✖ 后续会调试和支持 |
| 支持YAPI数据备份 | ✖ 后续会调试和支持 |

## 1.2 运行和配置mongo

### 1.2.1 运行mongo
yapi依赖mongo，如果维护有mongo集群，可以直接使用；如果没有，可以用[mongo/mongo.yml](mongo/mongo.yml)启动mongo：
```bash
docker-compose -f mongo.yml up -d
```
> 
> * 默认用户名`root`，默认密码`123456`，强烈建议修改。
> * `mongo-express`是mongo官方的Web界面，建议安装，方便通过Web界面操作mongo
> * `my_docker_net`是自定义的docker网络，应该和yapi在同一个docker网络下
> * mongo的数据挂载在`/opt/mongo`目录下
> * [mongo镜像](https://hub.docker.com/_/mongo)，[mongo-express镜像](https://hub.docker.com/_/mongo-express)

### 1.2.2 配置yapi相关数据
yapi需要一个管理数据库的用户，可以通过如下命令创建：
```bash
docker exec -it xxxxxx /bin/bash # 进入mongo容器，其中xxxx是容器的container_id
mongo # 使用mongo客户端
use admin # 使用admin数据库
db.auth("root","123456") # 校验root用户身份
# 创建yapi用户
db.createUser({
    user: "yapiDatabaseAdmin",
    pwd: "123456",
    roles:[
       {
           role:"readWrite",
           db:"yapi"
       }
    ]
})

```

> * 创建的用户：用户名`yapiDatabaseAdmin`, 密码`123456`，强烈建议修改。
> * 该用户权限为数据库`yapi`的`readWrite`权限，其中`yapi`应与后面的`YAPI_DB_DATABASE`值保持一致

## 1.3 运行docker-yapi

### 1.3.1 拉取镜像
```bash
docker pull bewindoweb/yapi:latest
```

### 1.3.2 修改docker环境变量
> * docker-compose配置文件在[docker-compose.yml](docker-compose.yml)
> * 注意有的参数带引号，有的不带引号

#### 1.3.2.1 基本配置

| 环境变量名 | 含义 | 默认值 | 是否建议关注或修改 | 备注 |
| --- | --- | --- | --- | --- |
| YAPI_PORT | 端口 | 9233 | - | |
| YAPI_ADMIN_ACCOUNT | 管理员邮箱 | yapiAdmin@example.com | ✔ | |
| YAPI_ADMIN_PASSWORD | 管理员密码 | yapiAdminPassword | ✔ | 【自定义配置】相比于原生yapi，增加了密码配置功能，可设置密码 |
| YAPI_CLOSE_REGISTER | 是否关闭注册 | true | ✔ | |
| YAPI_VERSION | YAPI版本号 | 1.8.5 | - | 【自定义配置】目前仅作展示，暂不支持更新版本 |
| YAPI_MODE | YAPI模式 | DEFAULT | ✔ | 【自定义配置】DEFAULT：第一次启动之后，之后的启动不再执行安装命令，修改配置将不会生效<br>REINSTALL：修改任意配置之后（比如改变管理员密码），重新安装一次 |

#### 1.3.2.2 mongo数据库配置
| 环境变量名 | 含义 | 默认值 | 是否建议修改 | 备注 |
| --- | --- | --- | --- | --- |
| YAPI_DB_CONNECT_STRING | MongoDB集群连接字符串 | 空 | ✔ | 如果mongo是单实例，则不用填写；如果是集群模式，则需要填写。<br>示例：mongodb://127.0.0.100:8418,127.0.0.101:8418,127.0.0.102:8418/yapidb?slaveOk=true |
| YAPI_DB_SERVER_NAME | MongoDB URL或容器服务名 | mongo | ✔ | 需要确保容器能够访问到该mongo服务器地址 |
| YAPI_DB_DATABASE | 存储yapi数据的MongoDB数据库 | yapi | - | |
| YAPI_DB_PORT | MongoDB端口 | 27017 | - | |
| YAPI_DB_USER | MongoDB操作yapi数据库的用户名 | yapiDatabaseAdmin | ✔ | |
| YAPI_DB_PASS | MongoDB操作yapi数据库的密码 | 123456 | ✔ | |
| YAPI_DB_AUTH | MongoDB身份校验数据库名 | admin | - | |

#### 1.3.2.3 邮箱配置
| 环境变量名 | 含义 | 默认值 | 是否建议修改 | 备注 |
| --- | --- | --- | --- | --- |
| YAPI_MAIL_ENABLE | 是否启用邮箱功能 | false | ✔ | |
| YAPI_MAIL_HOST | 邮箱服务器 | smtp.163.com | ✔ | |
| YAPI_MAIL_PORT | 邮箱端口 | 465 | ✔ | |
| YAPI_MAIL_FROM | 发件人邮箱 | yapiMailSender@163.com | ✔ | |
| YAPI_MAIL_AUTH_USER | 邮箱服务器帐号 | yapiMailAdmin@163.com | ✔ | |
| YAPI_MAIL_AUTH_PASS | 邮箱服务器密码 | yapiMailPassword | ✔ | |

> [如何开通电子邮箱的SMTP功能](https://jingyan.baidu.com/article/fdbd42771da9b0b89e3f48a8.html)


#### 1.3.2.4 LDAP配置
| 环境变量名 | 含义 | 默认值 | 是否建议修改 | 备注 |
| --- | --- | --- | --- | --- |
| YAPI_LDAP_LOGIN_ENABLE | 是否支持LDAP登录 | false | ✔ | |
| YAPI_LDAP_LOGIN_SERVER | LDAP服务器地址 | ldap://ldapServer:389 | ✔ | |
| YAPI_LDAP_LOGIN_BASE_DN | LDAP服务器登录用户名 | - | ✔ | 示例：cn=Manager,dc=example,dc=com |
| YAPI_LDAP_LOGIN_BIND_PASSWORD | 登录该LDAP服务器的密码 | - | ✔ | 示例：123456 |
| YAPI_LDAP_LOGIN_SEARCH_DN | 查询用户数据的路径 | dc=example,dc=com | ✔ | |
| YAPI_LDAP_LOGIN_SEARCH_STANDARD | 查询条件 | mail | ✔ | |
| YAPI_LDAP_LOGIN_EMAIL_POSTFIX | 登陆邮箱后缀 | 空 | ✔ | 示例：@example.com |
| YAPI_LDAP_LOGIN_EMAIL_KEY | ldap数据库存放邮箱信息的字段 | 空 | ✔ | 示例：mail |
| YAPI_LDAP_LOGIN_USERNAME_KEY | ldap数据库存放用户名信息的字段 | 空 | ✔ | 示例：description |

> [YAPI官方关于LDAP参数说明](https://hellosean1025.github.io/yapi/devops/index.html#%e9%85%8d%e7%bd%aeldap%e7%99%bb%e5%bd%95)

#### 1.3.2.5 暂不支持的配置
| 环境变量名 | 含义 | 默认值 | 是否建议修改 | 备注 |
| --- | --- | --- | --- | --- |
| YAPI_PLUGIN | YAPI插件列表 | 空 | - | 目前安装插件会出现`ESLint Configuration not exist`的错误，暂未解决 |
> [YAPI插件列表](https://www.npmjs.com/search?q=yapi-plugin-)

### 1.3.3 运行yapi容器
```bash
docker-compose -f docker-compose.yml up -d
```

# 2 nginx代理
nginx代理：推荐使用nginx将YAPI用https暴露出去。

# 3 YAPI数据备份
只需要备份mongo中的数据即可。  
可以使用[backup/yapi_backup.sh](yapi_backup.sh)中的思路，参考文章[API集成管理平台YAPI的搭建和使用——YAPI7天备份脚本 | 三颗豆子](http://www.bewindoweb.com/222.html)

# 4 相关链接
* [YAPI Docker集成 | 三颗豆子](http://www.bewindoweb.com/222.html)
