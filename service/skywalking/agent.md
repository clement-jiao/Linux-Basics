## agent 启动方式

### tomcat7.8.9
```bash
# vim tomcat/bin/catalina.sh
# 核心在于加入以下 jvm 启动参数，使 sw-agent 成为 jvm 启动代理，其余 java 程序亦是如此。
CATALINA_OPTS="$CATALINA_OPTS -javaagent:/path/to/skywalking-agent/skywalking-agent.jar";
export CATALINA_OPTS


# jar 包
# 格式1：（未验证）
java -javaagent:/path/to/skywalking-agent.jar={config1}={value1},{config2}={value2}
# 示例：
java -javaagent:/opt/skywalking-agent.jar=agent.service_name=fw-gateway,collector.backend_service=127.0.0.1:11800

# 格式2：（生产在用）
java -javaagent:/path/to/skywalking-agent.jar -Dskywalking.[option1]=[value2]
# 示例：
java -javaagent:/opt/apache-skywalking-apm-bin/agent/skywalking-agent.jar -Dskywalking.agent.service_name=starsky-generator -Dskywalking.collector.backend_service=localhost:11800 -jar starsky-generator-1.0.0.jar

```
### APM
其余 APM 可在此查找：https://github.com/SkyAPM
