## compile stage
FROM node:10.18.1-alpine3.11 as build-stage
MAINTAINER bewindoweb<bewindoweb1995@foxmail.com>

ARG APK_REPO=" \
	https://mirrors.aliyun.com/alpine/v3.11/main/\n\
	https://mirrors.aliyun.com/alpine/v3.11/community/\n\
"
RUN echo -e ${APK_REPO} > /etc/apk/repositories
RUN apk update && apk add --no-cache git python make openssl tar gcc

RUN mkdir -p /opt/yapi/vendors
WORKDIR /opt/yapi/vendors
RUN wget https://github.com/YMFE/yapi/archive/v1.8.5.tar.gz
RUN tar -zxf v1.8.5.tar.gz -C ./ && rm -rf v1.8.5.tar.gz
RUN mv yapi-1.8.5/* ./ && rm -rf yapi-1.8.5
COPY config.json ../config.json
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh
RUN sed -i -e 's/yapi.commons.generatePassword(/yapi.commons.generatePassword(yapi.WEBCONFIG.adminPassword || /' "./server/install.js"
RUN sed -i -e 's/密码："ymfe.org"/密码："${yapi.WEBCONFIG.adminPassword || \"ymfe.org\"}"/' "./server/install.js"
RUN sed -i "26i\\\
  userInst.findByEmail(yapi.WEBCONFIG.adminAccount).exec((err,dupAdmin)=>{\n\
    if (dupAdmin) {\n\
      console.log(\`find duplicated adminAccount, username=\${dupAdmin.username}, will be delete\`);\n\
      userInst.del(dupAdmin._id).exec();\n\
    }\n\
  });\n" \
"./server/install.js"

## running stage
FROM node:10.18.1-alpine3.11 as running-stage
MAINTAINER bewindoweb<bewindoweb1995@foxmail.com>

ARG APK_REPO=" \
	https://mirrors.aliyun.com/alpine/v3.11/main/\n\
	https://mirrors.aliyun.com/alpine/v3.11/community/\n\
"
RUN echo -e ${APK_REPO} > /etc/apk/repositories \
&& apk update && apk add --no-cache python make bash \
&& npm install -g yapi-cli ykit --registry https://registry.npm.taobao.org

COPY --from=build-stage /opt/yapi /opt/yapi
WORKDIR /opt/yapi/vendors

EXPOSE ${YAPI_PORT}
VOLUME ["/opt/yapi/vendors/log"]
ENTRYPOINT ["/opt/yapi/vendors/entrypoint.sh"]
