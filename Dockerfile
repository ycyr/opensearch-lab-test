FROM opensearchproject/opensearch:2.0.0

ENV AWS_ACCESS_KEY_ID XXXX
ENV AWS_SECRET_ACCESS_KEY XXX


RUN /usr/share/opensearch/bin/opensearch-plugin install --batch repository-s3
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch https://github.com/aiven/encrypted-repository-opensearch/releases/download/v2.0.0.0/encrypted-repository-2.0.0.0.zip
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch  https://github.com/aiven/prometheus-exporter-plugin-for-opensearch/releases/download/2.0.0.0/prometheus-exporter-2.0.0.0.zip

RUN /usr/share/opensearch/bin/opensearch-keystore create

RUN echo $AWS_ACCESS_KEY_ID | /usr/share/opensearch/bin/opensearch-keystore add --stdin s3.client.default.access_key
RUN echo $AWS_SECRET_ACCESS_KEY | /usr/share/opensearch/bin/opensearch-keystore add --stdin s3.client.default.secret_key
ADD ./key.pem /usr/share/opensearch/key.pem
ADD ./public.pem /usr/share/opensearch/public.pem
RUN /usr/share/opensearch/bin/opensearch-keystore add-file --force encrypted.s3.default.private_key /usr/share/opensearch/key.pem
RUN /usr/share/opensearch/bin/opensearch-keystore add-file --force encrypted.s3.default.public_key /usr/share/opensearch/public.pem
ADD https://github.com/corretto/amazon-corretto-crypto-provider/releases/download/1.6.1/AmazonCorrettoCryptoProvider-1.6.1-linux-x86_64.jar /usr/share/opensearch/plugins/encrypted-repository/
ADD https://raw.githubusercontent.com/corretto/amazon-corretto-crypto-provider/develop/etc/amazon-corretto-crypto-provider-jdk15.security   /usr/share/opensearch/config/amazon-corretto-crypto-provider.security
RUN echo "encrypted.security_provider: com.amazon.corretto.crypto.provider.AmazonCorrettoCryptoProvider" >> /usr/share/opensearch/config/opensearch.yml


USER root
RUN chown opensearch:opensearch /usr/share/opensearch/config/amazon-corretto-crypto-provider.security
RUN chown -R opensearch:opensearch /usr/share/opensearch/plugins/encrypted-repository/
USER opensearch
