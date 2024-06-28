# 1. 重要说明

SDK 类只能按照包名引用，不能直接引入 SDK 内部文件夹的类

我们只保证对外的 类、接口和枚举值 的兼容性，不保证内部的 类、接口、枚举值 的兼容性

> 正例

```ts
import { IMEngine } from '@rongcloud/imlib';
```

> 反例

不能直接导入 SDK 内部文件夹的内容，不能出现 **src/main/ets/** 具体文件夹路径

如果导入 SDK 内部路径，后续 SDK 重构修改路径可能出现路径错误

```ts
import { IMEngine } from '@rongcloud/imlib/src/main/ets/engine/IMEngine';
```

# 1. 初始化相关接口
## 1.1 获取 IMEngine 实例
```ts
/** 单例对象 **/
public static getInstance(): IMEngine;
```

## 1.2 初始化
```ts
/**
 * 初始化 SDK
 * @param context 上下文，为空的话则初始化失败
 * @param appKey 融云 appKey，为空的话则初始化失败
 * @param initOption 初始化配置，见 InitOption
 */
public init(context: common.Context,
            appKey: string,
            initOption: InitOption): void
```

> 示例代码
```ts
// IndexPage.ets

// 在 Page 中获取 context
let context = getContext(this);

// 在 UIAbility 中获取 context
// let context = this.context

let initOption = new InitOption();
let appKey = "从融云后台获取的 appKey";
IMEngine.getInstance().init(context, appKey, initOption);
```

### 1.2.1 初始化配置
可以通过 InitOption 设置区域码，手动设置导航地址、统计服务地址、媒体存储路径

```ts
class InitOption {
  /**
   * 数据中心区域码
   *
   * 默认为北京数据中心，用户可以根据实际情况设置区域码，设置之后，SDK 将会使用特定区域的服务地址
   *
   * 每个数据中心都会有对应服务地址，如果开发者手动设置了本类的服务地址将会覆盖对应区域的配置
   * 
   * 例如：设置 areaCode 为北美数据中心，同时又设置了此处的 naviServer ，那么最终会使用此处的 naviServer 而不是北美数据中心的 naviServer
   */
  areaCode: AreaCode = AreaCode.BJ;
  /**
   * 导航服务地址
   *
   * 仅限独立数据中心使用，使用前必须先联系商务开通。
   *
   * @discussion 如果没有以 http(s):// 开头，SDK 会为其拼接 https:// ；如果以 http(s):// ，SDK 将直接使用
   */
  naviServer: string = "";
  /**
   * 统计服务器地址
   *
   * 仅限独立数据中心使用，使用前必须先联系商务开通。
   *
   * @discussion 如果没有以 http(s):// 开头，SDK 会为其拼接 https:// ；如果以 http(s):// ，SDK 将直接使用
   */
  statisticServer: string = "";
  /**
   * 文件下载路径
   *
   * 实际路径为 context.filesDir + "/" + mediaSavePath
   */
  mediaSavePath: string = "RongCloud/Media/";
}
```


## 1.3 获取 SDK 版本号
```ts
/**
 * 获取 SDK 版本号
 * @returns 版本号
 */
public getVersion(): string
```

> 示例代码
```ts
let ver = IMEngine.getInstance().getVersion();
```

## 1.4 设置 APP 版本

注意：SDK 初始化时就会使用该字段，所以必须在 init 之前调用；否则不会生效

```ts
/**
 * 上报 APP 版本信息，服务端支持按上报的 App 版本处理自定义消息的推送内容
 *
 * @param ver APP 版本，string 类型，非空，长度小于 20, 示例如 "1.1.0"
 * @note 当 SDK 初始化时就会用该字段，所以必须在 init 之前调用
 */
public setAppVersion(ver: string): void {
  this.impl.setAppVersion(ver);
}
```

> 示例代码
```ts
IMEngine.getInstance().setAppVersion("1.0.0");
```

## 1.5 设置推送 token

```ts
/**
 * 设置鸿蒙推送 token
 * @param pushToken 推送 token
 * @note 需要在初始化之后调用。SDK 连接成功前设置，连接成功后 SDK 自动上传；连接成功后设置 SDK 立即上传
 */
public setPushToken(pushToken: string): void {
  this.impl.setPushToken(pushToken);
}
```

> 调用示例

获取推送 token 参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-token-0000001727725878

如果获取失败，参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-error-code-0000001727929904#section3835124673016

```ts
pushService.getToken((error: BusinessError, token: string) => {
  if (token) {
    IMEngine.getInstance().setPushToken(token);
  }
  hilog.info(0x0000, 'IM-ArkTS', 'getPushToken error:%{public}s token:%{public}s', error, token);
});
```

## 1.6 设置日志级别

```ts
/**
 * 设置控制台日志级别
 * @param level 日志级别，用于过滤控制台的日志输出
 * @discussion 例如：填入 LogLevel.None ，SDK 将不再控制台输出日志
 * @discussion 例如：填入 LogLevel.Warn ，SDK 将会在控制台输出 Warn 和 Error 的日志
 */
public setLogLevel(level: LogLevel) : void {
  FwLog.setLogLevel(level);
  this.impl.setLogLevel(level);
}
```

> 示例代码
```ts
IMEngine.getInstance().setLogLevel(LogLevel.Info);
```

在 DevEco-Studio 的控制台输入 **IM-** 即可过滤 IM 的日志



# 2. 连接相关接口
## 2.1 连接
```ts
/**
 * 连接 IM
 *
 * 调用该接口，SDK 会在 timeLimit 秒内尝试重连，直到出现下面三种情况之一
 * ```
 * 第一、连接成功，回调 IConnectResult.code === EngineError.Success
 * 第二、超时，回调 IConnectResult.code === EngineError.ConnectionTimeout，需要手动调用该接口继续连接
 * 第三、出现 SDK 无法处理的错误，回调 IConnectResult.code 为具体的错误码
 *
 * 常见的错误如下：
 * ClientNotInit ：SDK 没有初始化，请先调用 init 接口
 *
 * ConnectTokenIncorrect ：检查一下 APP 使用的 appKey 和 APP Server 使用的 appKey 是否相同
 *
 * ConnectOneTimePasswordUsed ：重新请求 Token
 * ConnectPlatformError ：重新请求 Token
 * ConnectTokenExpired ：重新请求 Token
 *
 * ConnectUserDeleteAccount ：给用户提示已销号
 * DisconnectUserKicked ：给用户提示被提掉线
 * ConnectUserBlocked ：给用户提示被封禁
 * DisconnectUserBlocked ：给用户提示被封禁
 * ```
 *
 * @param token 从您服务器端获取的 token (用户身份令牌)
 * @param timeout 超时时间，整型，单位秒，timeout <= 0：不设置超时时长，一直连接直到成功或失败；timeout > 0: 在对应的时间内连接未成功则返回超时错误
 * @returns 连接结果
 *
 * @note 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。
 *
 * @see IConnectResult
 */
public connect(token: string, timeout: number): Promise<IConnectResult> 
```

> 示例代码
```ts
let token = "IMToken";
let timeout = 5;

hilog.info(0x0000, 'IM-App', 'connect token:%{public}s', token);
IMEngine.getInstance().connect(token, timeout)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'connect result :%{public}s', JSON.stringify(result));
  });
```

## 2.2 设置连接状态监听
```ts
/**
 * 设置连接状态监听。每个连接状态都有详细的描述和处理意见
 * ```
 * 常见的错误如下：
 * DisconnectTokenIncorrect ： 检查一下 APP 使用的 appKey 和 APP Server 使用的 appKey 是否相同
 * DisconnectTokenExpired ： 重新请求 Token
 * DisconnectUserKicked ： 给用户提示被提掉线
 * DisconnectConnectionTimeout ： 连接超时，需要主动调用连接接口
 * ```
 * @param listener 监听
 * @see ConnectionStatus
 */
public setConnectionStatusListener(listener: (status: ConnectionStatus) => void): void
```

> 示例代码

```ts
hilog.info(0x0000, 'IM-App', 'setConnectionStatusListener');
IMEngine.getInstance().setConnectionStatusListener((status: ConnectionStatus) => {
  hilog.info(0x0000, 'IM-App', 'setConnectionStatusListener onChanged status:%{public}d', status);
});
```

## 2.3 获取当前连接状态
```ts
/**
 * 获取当前连接状态
 * @returns 连接状态
 * @see ConnectionStatus
 */
public getCurrentConnectionStatus(): Promise<IAsyncResult<ConnectionStatus>>
```

> 示例代码
```ts
IMEngine.getInstance().getCurrentConnectionStatus()
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getCurrentConnectionStatus result :%{public}s', JSON.stringify(result));
  });
```

## 2.4 获取当前用户 ID
```ts
/**
 * 获取当前用户 ID
 * @returns 连接成功后才会有值
 */
public getCurrentUserId(): Promise<IAsyncResult<string>>
```

> 示例代码
```ts
IMEngine.getInstance().getCurrentUserId()
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getCurrentUserId result :%{public}s', JSON.stringify(result));
  });
```


## 2.5 断开连接
```ts
/**
 * 断开连接
 * @param isReceivePush 是否接受推送
 * @note SDK 在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性，除非您的 App 逻辑需要登出，否则一般不需要调用此方法进行手动断开
 */
public disconnect(isReceivePush: boolean): void
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'disconnect start');

IMEngine.getInstance().disconnect(true);
```

# 3. 消息相关接口
## 3.1 设置消息接收监听
```ts
/**
 * 设置消息接收监听
 * @param listener 监听
 * @note 刷新逻辑参考 ReceivedInfo
 */
public setMessageReceivedListener(listener: (message: Message, info: ReceivedInfo) => void): void

/**
 * 消息接收信息
 * @note 建议当 left = 0 并且 hasPackage = false 时刷新 UI
 */
class ReceivedInfo {
  /**
   * 还剩余的未接收的消息数，left>=0
   */
  left: number = 0;
  /**
   * SDK 拉取服务器的消息以包(package)的形式批量拉取，有 package 存在就意味着远端服务器还有消息尚未被 SDK 拉取
   */
  hasPackage: boolean = false;
  /**
   * 是否是离线消息
   */
  isOffline: boolean = false;
}
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'setMessageReceivedListener start');
IMEngine.getInstance().setMessageReceivedListener((message: Message, info: ReceivedInfo) => {
  
});
```

## 3.2 设置消息撤回监听
```ts
/**
 * 设置消息撤回监听，撤回了之后，原始消息会变成 RecallNotificationMessage 消息
 * @param listener 监听
 */
public setMessageRecalledListener(listener: (message: Message, recallMessage: RecallNotificationMessage) => void): void
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'setMessageRecalledListener start');
IMEngine.getInstance().setMessageRecalledListener((message: Message, recallMessage: RecallNotificationMessage) => {
  hilog.info(0x0000, 'IM-App', 'setMessageRecalledListener result message:%{public}s recallMessage:%{public}s', JSON.stringify(message), JSON.stringify(recallMessage));
});
```

## 3.3 设置消息敏感词拦截监听
```ts
/**
 * 设置消息敏感词拦截监听
 * @param listener 监听
 * @discussion 当发送消息触发敏感词拦截的时候，会触发该回调
 * @see MessageBlockInfo
 */
public setMessageBlockedListener(listener: (blockInfo: MessageBlockInfo) => void): void

/**
 * 消息拦截信息
 * @version 0.0.1
 */
class MessageBlockInfo {
  /**
   * 会话类型
   */
  conversationType: ConversationType = ConversationType.Private;
  /**
   * 会话 ID
   */
  targetId: string = "";
  /**
   * 被拦截的消息 UID
   */
  messageUid: string = "";
  /**
   * 附加信息
   */
  extra: string = "";
  /**
   * 拦截类型
   */
  blockType: MessageBlockType = MessageBlockType.None;
  /**
   * 消息被拦截的触发来源
   */
  sourceType: MessageBlockSourceType = MessageBlockSourceType.Default;
  /**
   * 源内容 Json 字符串，sourceType 为 1、2 时返回
   *
   * sourceType 为 0，sourceContent 内容为 nil
   *
   * sourceType 为 1，sourceContent 是扩展内容，示例 {"mid":"xxx-xxx-xxx-xxx","put":{"key":"敏感词"}}
   *
   * sourceType 为 2，sourceContent 是消息修改后内容，示例 {"content":"敏感词"}
   */
  sourceContent: string = "";
}

/**
 * 拦截类型
 * @version 0.0.1
 */
enum MessageBlockType {
  None = 0,
  /**
   * 全局敏感词：命中了融云内置的全局敏感词
   */
  BlockGlobal = 1,
  /**
   * 自定义敏感词拦截：命中了客户在融云自定义的敏感词
   */
  BlockCustom = 2,
  /**
   * 第三方审核拦截：命中了第三方（数美）或消息回调服务决定不下发的状态
   */
  BlockThirdParty = 3,
}

/**
 * 消息被拦截的触发来源
 * @version 0.0.1
 */
enum MessageBlockSourceType {
  /**
   * 默认，原始消息内容被拦截
   */
  Default = 0,

  /**
   * 消息扩展被拦截
   */
  Extension = 1,

  /**
   * 修改的消息内容被拦截
   */
  Modification = 2,
}
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'setMessageBlockedListener start');
IMEngine.getInstance().setMessageBlockedListener((blockInfo: MessageBlockInfo) => {
  hilog.info(0x0000, 'IM-App', 'setMessageBlockedListener result blockInfo:%{public}s', JSON.stringify(blockInfo));
});
```

3.4 发送普通消息
```ts
/**
 * 发送消息
 * @param message 消息对象
 * @param option 消息发送的配置
 * @param saveCallback 消息入库的回调，
 * @returns 消息发送结果
 * @discussion 只有入库成功才会走 savedCallback，其他的情况：非法参数、入库失败、发送不入库的消息等都不会走 savedCallback 直接走 resultCallback
 * @note SDK 内置消息都有推送，自定义消息必须设置 Message.pushConfig
 */
public sendMessage(message: Message,
                   option: ISendMsgOption,
                   saveCallback: (msg: Message) => void): Promise<IAsyncResult<Message>>
``` 

> 示例代码
```ts
// 创建会话标识
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

// 创建文本消息
let textMsg = new TextMessage();
textMsg.content = "from 鸿蒙 ";
textMsg.extra = "TestExtra";

let option: ISendMsgOption = {};

// 创建消息体
let msg = new Message(conId, textMsg);

// 发送消息
hilog.info(0x0000, 'IM-App', 'SendTextMessage start');
IMEngine.getInstance().sendMessage(msg,option,(msg: Message) => {
    // 消息入库回调
  hilog.info(0x0000, 'IM-App', 'SendTextMessage onSave msg:%{public}s', JSON.stringify(msg));
}).then(result => {
    // 消息发送结果
  hilog.info(0x0000, 'IM-App', 'SendTextMessage onResult :%{public}s', JSON.stringify(result));
})
```

## 3.5 发送媒体消息
文件消息，图片消息，高清语音消息

```ts
/**
 * 发送媒体消息
 * @param message 消息体
 * @param option 消息发送的配置
 * @param saveCallback 消息发送的配置
 * @param progressCallback 媒体文件上传进度
 * @returns 媒体消息发送结果
 * @discussion 只有入库成功才会走 savedCallback，其他的情况：非法参数、入库失败、发送不入库的消息等都不会走 savedCallback 直接走 resultCallback
 */
public sendMediaMessage(message: Message,
                        option: ISendMsgOption,
                        saveCallback: (msg: Message) => void,
                        progressCallback: (msg: Message, progress: number) => void,): Promise<IAsyncResult<Message>>
```

> 示例代码
```ts
// 创建会话标识
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

// 创建文件消息
let fileMsg = new FileMessage();
fileMsg.localPath = FileUtil.getFilePath(getContext(this));

let option: ISendMsgOption = {};

// 创建消息
let msg = new Message(conId, fileMsg);

// 发送媒体消息
hilog.info(0x0000, 'IM-App', 'sendMediaMessage file start');
IMEngine.getInstance().sendMediaMessage(msg, option, (message: Message) => {
    // 消息入库回调
  hilog.info(0x0000, 'IM-App', 'sendMediaMessage file onSave. message : %{public}s', JSON.stringify(message));
}, (msg: Message, progress: number) => {
    // 媒体上传进度回调
  hilog.info(0x0000, 'IM-App', 'sendMediaMessage file onProgress progress:%{public}d . message : %{public}s', progress, JSON.stringify(msg));
}).then(result => {
    // 消息发送结果
  hilog.info(0x0000, 'IM-App', 'sendMediaMessage file onResult : %{public}s', JSON.stringify(result));
});
```

## 3.6 下载媒体消息
```ts
/**
 * 下载媒体消息
 * @param messageId 消息 id
 * @returns 媒体消息下载成功的本地路径，存储路径见 InitOption.mediaSavePath
 * @note 调用该接口下载成功后，消息的本地路径会保存数据库中；相同的消息重复下载，会直接返回本地路径
 */
public downloadMediaMessage(messageId: number) : Promise<IAsyncResult<string>>
```

> 示例代码
```ts
IMEngine.getInstance().downloadMediaMessage(messageId).then(result => {
   hilog.info(0x0000, 'IM-App', 'downloadMediaMessage onResult : %{public}s', JSON.stringify(result));
});
```

## 3.7 发送消息携带用户信息和 @ 信息
```ts
- 携带用户信息
let textMsg = new TextMessage();
textMsg.content = "from 鸿蒙 ";
textMsg.extra = "TestExtra";

// 消息按需携带用户信息
textMsg.userInfo = new UserInfo("testUserId", "TestName", "TestUrl");
- 携带 @ 信息 - @ 部分用户
let textMsg = new TextMessage();
textMsg.content = "from 鸿蒙 ";
textMsg.extra = "TestExtra";

// 消息的 @ 信息
let mentionedInfo = new MentionedInfo();

// @ 类型为 @ 部分用户
mentionedInfo.type = MentionedType.PART;

// 保存 @ 的用户 id 列表
let userIdList = new Array<string>();
userIdList.push("TestUserId");
mentionedInfo.userIdList = userIdList;

// 把 @ 信息塞给消息体
textMsg.mentionedInfo = mentionedInfo;
- 携带 @ 信息 - @ 所有人
let textMsg = new TextMessage();
textMsg.content = "from 鸿蒙 ";
textMsg.extra = "TestExtra";

// 消息 @ 所有人
let mentionedInfo = new MentionedInfo();

// @ 类型为 @ 所有人
mentionedInfo.type = MentionedType.ALL;

// 把 @ 信息塞给消息体
textMsg.mentionedInfo = mentionedInfo;
```

## 3.8 发送消息携带 pushConfig
```ts
// 创建会话标识
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

// 创建文本消息
let textMsg = new TextMessage();
textMsg.content = "from 鸿蒙 ";
textMsg.extra = "TestExtra";

let option: ISendMsgOption = {};

// 创建消息体
let msg = new Message(conId, textMsg);

// 按需创建推送配置
let pushConfig = new PushConfig();
pushConfig.pushTitle = "TestPushTitle";
pushConfig.pushContent = "TestPushContent";
pushConfig.pushData = "TestPushData";
msg.pushConfig = pushConfig;
```

## 3.9 撤回消息
```ts
/**
 * 撤回消息
 * @param message 需要撤回的消息，发送成功的消息才能撤回（必须有有效的 MessageUid）
 * @returns 撤回成功后的小灰条消息
 * @discussion pushContent 用 Message.pushConfig
 */
public recallMessage(message: Message): Promise<IAsyncResult<RecallNotificationMessage>>
> 示例代码
IMEngine.getInstance().recallMessage(msg).then(result => {
  hilog.info(0x0000, 'IM-App', 'recallMessage result %{public}s', JSON.stringify(result));
});
```

## 3.10 注册自定义消息
```ts
/**
 * 注册自定义消息
 * ```
 * 自定义消息需要满足三点，具体可以参考 SDK 内置的 TextMessage
 * 1. 继承 MessageContent
 * 2. 实现 MessageTag 注解
 * 3. 实现无参构造方法
 * ```
 *
 * ```
 * //> 示例代码
 * let clazzList: List<MessageContentConstructor> = new List();
 * clazzList.add(TextMessage);
 * IMEngine.getInstance().registerMessageType(clazzList);
 * ```
 * @param msgClassList 自定义消息数组
 */
public registerMessageType(msgClassList: List<MessageContentConstructor>)

> 示例代码
let clazzList: List<MessageContentConstructor> = new List();
clazzList.add(CustomTextMessage);
clazzList.add(CustomOrderMessage);
IMEngine.getInstance().registerMessageType(clazzList);
```

## 3.11 消息批量入库
```ts
/**
 * 消息批量入库
 *
 * Message 下列属性会被入库，其他属性会被抛弃：
 * ```
 * conversationType   会话类型
 * targetId           会话 ID
 * direction          消息方向
 * senderId           发送者 ID
 * receivedStatus     接收状态
 * sentStatus         发送状态
 * sentTime           发送时间
 * content            消息内容
 * objectName         消息类型，设置 content 的时候 SDK 会自动赋值对应的 objectName
 * messageUid         服务端生产的消息唯一 ID
 * extra              扩展信息
 * ```
 * @param msgList 需要入库的消息，范围 [1 ~ 500]，会话类型不支持聊天室和超级群
 * @returns 入库结果
 */
public batchInsertMessage(msgList: List<Message>): Promise<IAsyncResult<void>>
> 示例代码
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let msgList = new List<Message>();
for (let i = 0; i < 5; i++) {
  let txtMsg = new TextMessage();
  txtMsg.content = "from 鸿蒙";

  let msg = new Message(conId, txtMsg);
  msg.direction = MessageDirection.Send;
  msg.senderId = "TestSenderId";
  msg.receivedStatus = new ReceivedStatus();
  msg.sentStatus = SentStatus.Sent;
  msg.sentTime = Date.now();
  msg.messageUid = "TestUid"; // 服务产生的唯一 id，没有的话就无需赋值
  msg.extra = "TestExtra"; // 按需赋值

  msgList.add(msg);
}

hilog.info(0x0000, 'IM-App', 'batchInsertMessage start');
IMEngine.getInstance().batchInsertMessage(msgList)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'batchInsertMessage result %{public}s', JSON.stringify(result));
  });
```

## 3.12 通过 messageId 获取单条消息
```ts
/**
 * 通过 messageId 获取单条消息
 * @param messageId 消息的本地数据库自增 ID
 * @returns 消息数据
 */
public getMessageById(messageId: number): Promise<IAsyncResult<Message>>
```
> 示例代码
```ts
IMEngine.getInstance().getMessageById(msg.messageId).then(result => {
  hilog.info(0x0000, 'IM-App', 'getMessageById onResult :%{public}s', JSON.stringify(result));
});
```

3.13 通过 messageUid 获取单条消息
```ts
/**
 * 通过 messageUid 获取单条消息
 * @param messageUid 消息发送成功后的服务唯一 ID
 * @returns 消息数据
 */
public getMessageByUid(messageUid: string): Promise<IAsyncResult<Message>>
```

> 示例代码
```ts
IMEngine.getInstance().getMessageByUid(msg.messageUid).then(result => {
  hilog.info(0x0000, 'IM-App', 'getMessageByUid onResult :%{public}s', JSON.stringify(result));
});
```
3.14 获取批量本地消息，基于 messageId 获取
```ts
/**
 * 获取批量本地消息，基于 messageId 获取
 * @param conId 会话标识
 * @param option 配置
 * @returns 返回本地消息结果
 * @see ConversationIdentifier
 * @see IGetLocalMsgByIdOption
 */
public getHistoryMessagesById(conId: ConversationIdentifier,
                              option: IGetLocalMsgByIdOption): Promise<IAsyncResult<List<Message>>>

/**
 * 获取本地消息的配置
 *
 * beforeCount afterCount 总共分为四种情况
 * ```
 * 1. beforeCount > 0 && afterCount > 0，将获取 beforeCount + {messageId} + afterCount 的消息
 * 2. beforeCount > 0 && afterCount == 0，将获取 beforeCount + {messageId} 的消息
 * 3. beforeCount == 0 && afterCount > 0，将获取 {messageId} + afterCount 的消息
 * 4. beforeCount == 0 && afterCount == 0，将获取 {messageId}
 * ```
 * @version 0.0.1
 */
interface IGetLocalMsgByIdOption {
  /**
   * objectName 集合，为空的话代表获取所有类型的本地消息
   *
   * 有效值的话代表获取指定类型的消息
   */
  objNameList?: List<string>,

  /**
   * 消息本地数据库 ID
   */
  messageId: number,

  /**
   * 在 messageId 之前的消息个数，取值 >=0
   * @discussion beforeCount 如果传入 10 ，但是获取的个数不足时说明往前没有更多的消息了
   */
  beforeCount: number,

  /**
   * 在 messageId 之后的消息个数，取值 >=0
   * @discussion afterCount 如果传入 10 ，但是获取的个数不足时说明往后没有更多的消息了
   */
  afterCount: number,
}
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let option: IGetLocalMsgByIdOption = {
  messageId: 100,
  beforeCount: 5,
  afterCount: 5
}

hilog.info(0x0000, 'IM-App', 'getHistoryMessagesById start');
IMEngine.getInstance().getHistoryMessagesById(conId, option)
  .then(result => {
    let msgList = result.data;
    if (ListChecker.isValid(msgList)) {
      hilog.info(0x0000, 'IM-App', 'getHistoryMessagesById result msgList is null or msgList is empty');
      return;
    }
    let len = msgList?.length;
    if (len === undefined) {
      len = 0;
    }
    for (let i = 0; i < len; i++) {
      let msg = msgList?.get(i);
      hilog.info(0x0000, 'IM-App', 'getHistoryMessagesById result messageId:%{public}d targetId:%{public}s objName:%{public}s uid:%{public}s', msg?.messageId, msg?.targetId, msg?.objectName, msg?.messageUid);
    }
  });
```

## 3.15 获取批量本地消息，基于 time 获取
```ts
/**
 * 获取批量本地消息，基于 time 获取
 * @param conId 会话标识
 * @param option 配置
 * @returns 返回本地消息结果
 * @see ConversationIdentifier
 * @see IGetLocalMsgByTimeOption
 */
public getHistoryMessagesByTime(conId: ConversationIdentifier,
                                option: IGetLocalMsgByTimeOption): Promise<IAsyncResult<List<Message>>>

/**
 * 获取本地消息的配置
 *
 * beforeCount afterCount 总共分为四种情况
 * ```
 * 1. beforeCount > 0 && afterCount > 0，将获取 beforeCount + {time} + afterCount 的消息
 * 2. beforeCount > 0 && afterCount == 0，将获取 beforeCount + {time} 的消息
 * 3. beforeCount == 0 && afterCount > 0，将获取 {time} + afterCount 的消息
 * 4. beforeCount == 0 && afterCount == 0，将获取 {time}
 * ```
 * @version 0.0.1
 */
interface IGetLocalMsgByTimeOption {
  /**
   * objectName 集合，为空的话代表获取所有类型的本地消息
   *
   * 有效值的话代表获取指定类型的消息
   */
  objNameList?: List<string>,

  /**
   * 毫秒时间戳
   * 初次可以传入当前时间: Date.now() 或者传入会话的 lastSentTime
   * @see Conversation
   */
  time: number,

  /**
   * 在 messageId 之前的消息个数，取值 >=0
   * @discussion beforeCount 如果传入 10 ，但是获取的个数不足时说明往前没有更多的消息了
   */
  beforeCount: number,

  /**
   * 在 messageId 之后的消息个数，取值 >=0
   * @discussion afterCount 如果传入 10 ，但是获取的个数不足时说明往后没有更多的消息了
   */
  afterCount: number,
}
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let option: IGetLocalMsgByTimeOption = {
  time: Date.now(),
  beforeCount: 5,
  afterCount: 5
};

hilog.info(0x0000, 'IM-App', 'getHistoryMessagesByTime start');
IMEngine.getInstance().getHistoryMessagesByTime(conId, option)
  .then(result => {
    let msgList = result.data;
    if (msgList === undefined || msgList?.isEmpty()) {
      hilog.info(0x0000, 'IM-App', 'getHistoryMessagesByTime result msgList is null or msgList is empty');
      return;
    }
    for (let i = 0; i < msgList?.length; i++) {
      let msg = msgList?.get(i);
      hilog.info(0x0000, 'IM-App', 'getHistoryMessagesByTime result messageId:%{public}d targetId:%{public}s objName:%{public}s uid:%{public}s', msg.messageId, msg.targetId, msg.objectName, msg.messageUid);
    }
  });
```

## 3.16 获取批量远端消息
```ts
/**
 * 获取批量远端消息
 * @param conId 会话标识
 * @param option 配置
 * @returns 返回远端消息结果
 * @note 此方法从服务器端获取之前的历史消息，但是必须先开通历史消息云存储功能
 * @see ConversationIdentifier
 * @see IGetLocalMsgByTimeOption
 */
public getRemoteHistoryMessages(conId: ConversationIdentifier,
                                option: IGetRemoteMsgOption): Promise<IAsyncResult<List<Message>>>

/**
 * 获取远端消息配置
 * @version 0.0.1
 */
interface IGetRemoteMsgOption {
  /**
   * 毫秒时间戳
   * 初次可以传入当前时间: Date.now() 或者传入 Conversation.lastSentTime
   */
  time: number,

  /**
   * 消息个数，[1 ~ 100]
   */
  count: number,

  /**
   * 获取的消息顺序
   *
   * Descending： 获取比 time 小的消息列表
   *
   * Ascending：获取比比 time 大的消息列表
   */
  order: Order,

  /**
   * 是否包含本地已存在消息
   *
   * @discussion true: 拉取回来的消息全部返回 ; false: 拉取回来的消息只返回本地数据库中不存在的
   */
  isCheckDup: boolean,
}
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let option: IGetRemoteMsgOption = {
  time: Date.now(),
  count: 10,
  order: Order.Descending,
  isCheckDup: true
}

hilog.info(0x0000, 'IM-App', 'getRemoteHistoryMessages start');
IMEngine.getInstance().getRemoteHistoryMessages(conId, option)
  .then(result => {
    let msgList = result.data;
    if (msgList === undefined || msgList?.isEmpty()) {
      hilog.info(0x0000, 'IM-App', 'getRemoteHistoryMessages result msgList is null or msgList is empty');
      return;
    }
    for (let i = 0; i < msgList?.length; i++) {
      let msg = msgList?.get(i);
      hilog.info(0x0000, 'IM-App', 'getRemoteHistoryMessages result messageId:%{public}d targetId:%{public}s uid:%{public}s', msg.messageId, msg.targetId, msg.messageUid);
    }
  });
```

3.17 获取本地会话中 @ 自己的消息
```ts
/**
 * 获取本地会话中 @ 自己的未读消息列表
 * @param conId 会话标识
 * @param option 配置
 * @returns 返回本地消息结果
 * @see ConversationIdentifier
 * @see ICountOption
 */
public getUnreadMentionedMessages(conId: ConversationIdentifier,
                                  option: ICountOption): Promise<IAsyncResult<List<Message>>>

/**
 * 个数配置
 * @version 0.0.1
 */
interface ICountOption {
  /**
   * 消息个数
   */
  count: number,

  /**
   * 获取数据顺序
   * @see Order
   */
  order: Order,
}
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let option: ICountOption = {
  count: 10,
  order: Order.Descending
};

hilog.info(0x0000, 'IM-App', 'getUnreadMentionedMessages start');
IMEngine.getInstance().getUnreadMentionedMessages(conId, option)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getUnreadMentionedMessages result :%{public}s', JSON.stringify(result));
  });
```

3.18 获取会话里第一条未读消息
```ts
/**
 * 获取会话里第一条未读消息
 * @param conId 会话标识
 * @returns 消息
 * @see ConversationIdentifier
 */
public getFirstUnreadMessage(conId: ConversationIdentifier): Promise<IAsyncResult<Message>>
> 示例代码
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'getFirstUnreadMessage start');
IMEngine.getInstance().getFirstUnreadMessage(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getFirstUnreadMessage result :%{public}s', JSON.stringify(result));
  });
```

## 3.19 删除本地会话的指定一批消息
```ts
/**
 * 删除本地会话的指定一批消息
 * @param messageIds 消息 ID 列表
 * @returns 删除结果
 */
public deleteHistoryMessagesByIds(messageIds: List<number>): Promise<IAsyncResult<void>>
> 示例代码
let idList = new List<number>();
idList.add(msg.messageId);

hilog.info(0x0000, 'IM-App', 'deleteHistoryMessagesByIds start by id : %{public}d', msg?.messageId);
IMEngine.getInstance().deleteHistoryMessagesByIds(idList).then(result => {
  hilog.info(0x0000, 'IM-App', 'deleteHistoryMessagesByIds onResult %{public}s', JSON.stringify(result));
});
```
## 3.20 清空本地指定会话的消息
```ts
/**
 * 清空本地会话的消息
 * @param conId 会话标识
 * @returns 结果
 * @see ConversationIdentifier
 */
public deleteMessages(conId: ConversationIdentifier): Promise<IAsyncResult<void>>
> 示例代码
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'deleteMessages start');
IMEngine.getInstance().deleteMessages(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'deleteMessages result %{public}s', JSON.stringify(result));
  });
```

## 3.21 删除本地会话特定时间前的所有消息
```ts
/**
 * 删除本地会话特定时间前的所有消息
 * @param conId 会话标识
 * @param sentTime 毫秒时间戳。清除 <= sentTime 的所有历史消息，若为 0 则代表清除所有消息
 * @returns 结果
 * @see ConversationIdentifier
 */
public deleteHistoryMessagesByTime(conId: ConversationIdentifier,
                                   sentTime: number): Promise<IAsyncResult<void>> 
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let sentTime = Date.now();
IMEngine.getInstance().deleteHistoryMessagesByTime(conId, sentTime)
  .then(result => {

    hilog.info(0x0000, 'IM-App', 'cleanLocalHistoryMessages result %{public}s', JSON.stringify(result));
  })
```

## 3.22 删除远端会话特定时间前的消息
```ts
/**
 * 删除远端会话特定时间前的消息
 * @param conId 会话标识
 * @param sentTime 毫秒时间戳。清除 <= sentTime 的所有历史消息，若为 0 则代表清除所有消息
 * @returns 结果
 * @see ConversationIdentifier
 */
public cleanRemoteHistoryMessagesByTime(conId: ConversationIdentifier,
                                        sentTime: number): Promise<IAsyncResult<void>>

```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let sentTime = Date.now();

hilog.info(0x0000, 'IM-App', 'cleanRemoteHistoryMessagesByTime start');
IMEngine.getInstance().cleanRemoteHistoryMessagesByTime(conId, sentTime)
  .then(result => {

    hilog.info(0x0000, 'IM-App', 'cleanRemoteHistoryMessagesByTime result %{public}s', JSON.stringify(result));

  });
```

# 4. 会话相关接口

## 4.1 设置会话状态（置顶，消息免打扰）变化监听
```ts
/**
 * 设置会话状态（置顶，消息免打扰）变化监听
 * @param listener 监听
 */
public setConversationStatusListener(listener: (items: List<ConversationStatusInfo>) => void): void

/**
 * 会话状态信息
 * @version 0.0.1
 */
class ConversationStatusInfo {
  /**
   * 会话类型
   */
  conversationType: ConversationType = ConversationType.Private;
  /**
   * 会话 ID
   */
  targetId: string = "";
  /**
   * 更新时间，毫秒
   */
  updateTime: number = 0;
  /**
   * 置顶时间，毫秒
   */
  topTime: number = 0;
  /**
   * 是否置顶
   */
  isTop: boolean = false;
  /**
   * 免打扰级别
   */
  level: PushNotificationLevel = PushNotificationLevel.Default;
}
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'setConversationStatusListener start');
IMEngine.getInstance().setConversationStatusListener((items: List<ConversationStatusInfo>) => {

  hilog.info(0x0000, 'IM-App', 'setConversationStatusListener result items:%{public}s', JSON.stringify(items));
});
```
## 4.2 获取单个会话
```ts
/**
 * 获取单个会话
 * @param conId 会话标识
 * @returns 会话数据
 * @see ConversationIdentifier
 */
public getConversation(conId: ConversationIdentifier): Promise<IAsyncResult<Conversation>>
> 示例代码
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'getConversation start');
IMEngine.getInstance().getConversation(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getConversation result:%{public}s', JSON.stringify(result));
  });
```
## 4.3 分页获取本地会话列表
```ts
/**
 * 分页获取本地会话列表
 * @param conTypeList 会话类型列表
 * @param option 配置
 * @returns 本地会话列表数据
 * @see IGetConversationOption
 */
public getConversationListByPage(conTypeList: List<ConversationType>,
                                 option: IGetConversationOption): Promise<IAsyncResult<List<Conversation>>>

/**
 * 获取会话配置
 * @version 0.0.1
 */
interface IGetConversationOption {
  /**
   * 会话的毫秒时间戳，返回小于该时间的会话；如果为 0，则查询全部。当分页时，可以传入上一次查询的最后一条消息的发送时间
   */
  time: number,

  /**
   * 获取的数量（当实际取回的会话数量小于 count 值时，表明已取完数据）
   */
  count: number,
}
```

> 示例代码
```ts
let conTypeList = new List<ConversationType>();
conTypeList.add(ConversationType.Private);
conTypeList.add(ConversationType.Group);

let option: IGetConversationOption = {
  time: Date.now(),
  count: 10
}

hilog.info(0x0000, 'IM-App', 'getConversationListByPage start');
IMEngine.getInstance().getConversationListByPage(conTypeList, option)
  .then(result => {
    let conversationList = result.data;
    if (!conversationList?.isEmpty()) {
      conversationList?.forEach(con => {
        hilog.info(0x0000, 'IM-App', 'getConversationListByPage result conversation:%{public}s', JSON.stringify(con));
      });
    } else {
      hilog.info(0x0000, 'IM-App', 'getConversationListByPage result count:0');
    }
  });
```

## 4.4 分页获取本地置顶会话列表
```ts
/**
 * 分页获取本地置顶会话列表
 * @param conTypeList 会话类型列表
 * @param option 配置
 * @returns 本地会话列表数据
 * @see IGetConversationOption
 */
public getTopConversationListByPage(conTypeList: List<ConversationType>,
                                    option: IGetConversationOption): Promise<IAsyncResult<List<Conversation>>>
```

> 示例代码
```ts
let conTypeList = new List<ConversationType>();
conTypeList.add(ConversationType.Private);
conTypeList.add(ConversationType.Group);

let option: IGetConversationOption = {
  time: Date.now(),
  count: 10
}

hilog.info(0x0000, 'IM-App', 'getTopConversationListByPage start');
IMEngine.getInstance().getTopConversationListByPage(conTypeList, option)
  .then(result => {
    let conversationList = result.data;
    if (!conversationList?.isEmpty()) {
      conversationList?.forEach(con => {
        hilog.info(0x0000, 'IM-App', 'getTopConversationListByPage result conversation:%{public}s', JSON.stringify(con));
      });
    } else {
      hilog.info(0x0000, 'IM-App', 'getTopConversationListByPage result count:0');
    }
  });
```

## 4.5 分页获取本地免打扰会话列表
```ts
/**
 * 分页获取本地免打扰会话列表
 * @param conTypeList 会话类型列表
 * @param option 配置
 * @returns 本地会话列表数据
 * @see IGetConversationOption
 */
public getBlockedConversationListByPage(conTypeList: List<ConversationType>,
                                        option: IGetConversationOption): Promise<IAsyncResult<List<Conversation>>>
```

> 示例代码
```ts
let conTypeList = new List<ConversationType>();
conTypeList.add(ConversationType.Private);
conTypeList.add(ConversationType.Group);


let option: IGetConversationOption = {
  time: Date.now(),
  count: 10
}

hilog.info(0x0000, 'IM-App', 'getBlockedConversationListByPage start');
IMEngine.getInstance().getBlockedConversationListByPage(conTypeList, option)
  .then(result => {
    let conversationList = result.data;
    if (!conversationList?.isEmpty()) {
      conversationList?.forEach(con => {
        hilog.info(0x0000, 'IM-App', 'getBlockedConversationListByPage result type:%{public}d targetId:%{public}s notificationLevel:%{public}d', con.conversationType, con.targetId, con.notificationLevel);
      });
    } else {
      hilog.info(0x0000, 'IM-App', 'getBlockedConversationListByPage result count:0');
    }
  });
```

## 4.6 删除本地会话同时删除会话中的消息
```ts
/**
 * 删除本地会话同时删除会话中的消息
 * @param conTypeList 会话类型列表
 * @returns 结果
 */
public clearConversations(conTypeList: List<ConversationType>): Promise<IAsyncResult<void>> 
> 示例代码
let conTypeList = new List<ConversationType>();
conTypeList.add(ConversationType.Private);

hilog.info(0x0000, 'IM-App', 'clearConversations start');
IMEngine.getInstance().clearConversations(conTypeList)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'clearConversations result %{public}s', JSON.stringify(result));
  });
```
## 4.7 批量删除本地会话，但是不会删除消息
```ts
/**
 * 批量删除本地会话，但是不会删除消息
 * @param conIdList 会话标识数组
 * @returns 结果
 */
public removeConversations(conIdList: List<ConversationIdentifier>): Promise<IAsyncResult<void>>
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let list = new List<ConversationIdentifier>();
list.add(conId);

hilog.info(0x0000, 'IM-App', 'removeConversations start');
IMEngine.getInstance().removeConversations(list)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'removeConversations result %{public}s', JSON.stringify(result));
  });
```
## 4.8 批量 设置/取消 会话置顶
```ts
/**
 * 批量 设置/取消 会话置顶
 * @param conIdList 会话标识列表
 * @param option 配置
 * @returns 结果
 * @see ISetConversationTopOption
 */
public setConversationsToTop(conIdList: List<ConversationIdentifier>,
                             option: ISetConversationTopOption): Promise<IAsyncResult<void>>

/**
 * 置顶配置
 * @version 0.0.1
 */
interface ISetConversationTopOption {
  /**
   * 是否置顶
   */
  isTop: boolean,

  /**
   * 是否创建会话：对应的会话本地不存在时，true 将创建该会话； false 不创建该会话
   */
  isNeedCreate: boolean,
}
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let list = new List<ConversationIdentifier>();
list.add(conId);

let option: ISetConversationTopOption = {
  isTop: true, // 是否置顶
  isNeedCreate: true // 没有会话时是否创建该会话
}

hilog.info(0x0000, 'IM-App', 'setConversationsToTop start');
IMEngine.getInstance().setConversationsToTop(list, option)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'setConversationsToTop result %{public}s', JSON.stringify(result));
  });
```
## 4.9 获取会话置顶状态
```ts
/**
 * 获取会话置顶状态
 * @param conId 会话标识
 * @returns 是否置顶
 */
public getConversationTopStatus(conId: ConversationIdentifier): Promise<IAsyncResult<boolean>>
```
> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'getConversationTopStatus start');
IMEngine.getInstance().getConversationTopStatus(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getConversationTopStatus result :%{public}s', JSON.stringify(result));
  });
```
## 4.10 批量设置会话免打扰
```ts
/**
 * 批量设置会话免打扰
 * @param conIdList 会话标识列表
 * @param level 会话免打扰级别
 * @returns 结果
 */
public setConversationsNotificationLevel(conIdList: List<ConversationIdentifier>,
                                         level: PushNotificationLevel): Promise<IAsyncResult<void>>
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let list = new List<ConversationIdentifier>();
list.add(conId);

let level = PushNotificationLevel.Blocked;

hilog.info(0x0000, 'IM-App', 'setConversationsNotificationLevel start');
IMEngine.getInstance().setConversationsNotificationLevel(list, level)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'setConversationsNotificationLevel result %{public}s', JSON.stringify(result));
  });
```

## 4.11 获取单个会话免打扰状态
```ts
/**
 * 获取单个会话免打扰状态
 * @param conId 会话标识
 * @returns 会话免打扰级别
 */
public getConversationNotificationLevel(conId: ConversationIdentifier): Promise<IAsyncResult<PushNotificationLevel>>
> 示例代码
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'getConversationNotificationLevel start');
IMEngine.getInstance().getConversationNotificationLevel(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getConversationNotificationLevel result:%{public}d', JSON.stringify(result));
  });
```
## 4.12 保存/清空 会话草稿
```ts
/**
 * 保存/清空 会话草稿
 * @param conId 会话标识
 * @param draft 草稿：传入有效值代表保存草稿；传入空字符串代表清空草稿
 * @returns 结果
 */
public saveTextMessageDraft(conId: ConversationIdentifier,
                            draft: string): Promise<IAsyncResult<void>>
```
> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id
let draft = "draft From 鸿蒙";

hilog.info(0x0000, 'IM-App', 'saveTextMessageDraft start');
IMEngine.getInstance().saveTextMessageDraft(conId, draft)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'saveTextMessageDraft result %{public}s', JSON.stringify(result));
  });
```
## 4.13 获取会话草稿
```ts
/**
 * 获取会话草稿
 * @param conId 会话标识
 * @returns 草稿
 */
public getTextMessageDraft(conId: ConversationIdentifier): Promise<IAsyncResult<string>> 
```
> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'getLocalTextDraft start');
IMEngine.getInstance().getTextMessageDraft(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getLocalTextDraft result:%{public}s', JSON.stringify(result));
  })
```
## 4.14 屏蔽某个时间段的消息提醒
```ts
/**
 * 屏蔽某个时间段的消息提醒
 * @param option 配置，见 IQuietHoursOption
 * @returns 结果
 * @discussion 此方法设置的屏蔽时间会在每天该时间段时生效。
 */
public setNotificationQuietHoursLevel(option: IQuietHoursOption): Promise<IAsyncResult<void>>

/**
 * @version 0.0.1
 */
interface IQuietHoursOption {
  /**
   * 开始消息免打扰时间，格式为 HH:MM:SS
   */
  startTime: string,

  /**
   * 需要消息免打扰分钟数，[1 ~ 1439]
   *
   *  比如，您设置的起始时间是 00：00， 结束时间为 01:00，则 spanMins 为 60 分钟。设置为 1439 代表全天免打扰 （23 * 60 + 59 = 1439 ）
   */
  duration: number,

  /**
   * 消息通知级别，Default 代表移除免打扰
   */
  level: PushNotificationLevel,
}
```

> 示例代码
```ts
let option: IQuietHoursOption = {
  startTime: "00:30:00",
  duration: 300,
  level: PushNotificationLevel.Blocked
}

hilog.info(0x0000, 'IM-App', 'setNotificationQuietHoursLevel start');
IMEngine.getInstance().setNotificationQuietHoursLevel(option)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'setNotificationQuietHoursLevel result %{public}s', JSON.stringify(result));
  })
```
## 4.15 查询已设置的时间段消息提醒屏蔽
```ts
/**
 * 查询已设置的时间段消息提醒屏蔽
 * @returns 具体的配置
 */
public getNotificationQuietHoursLevel(): Promise<IAsyncResult<IQuietHoursOption>>
```
> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'getNotificationQuietHoursLevel start');
IMEngine.getInstance().getNotificationQuietHoursLevel()
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getNotificationQuietHoursLevel result :%{public}s', JSON.stringify(result));
  })
```
## 4.16 删除已设置的全局时间段消息提醒屏蔽
```ts
/**
 * 删除已设置的全局时间段消息提醒屏蔽
 * @returns 结果
 * @version 1.0.0
 */
public removeNotificationQuietHours(): Promise<IAsyncResult<void>>
```
> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'removeNotificationQuietHours start');
IMEngine.getInstance().removeNotificationQuietHours()
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'removeNotificationQuietHours result %{public}s', JSON.stringify(result));
  });
```
## 4.17 获取本地会话的全部未读数
```ts
/**
 * 获取本地会话的全部未读数
 * @returns 未读数
 */
public getTotalUnreadCount(): Promise<IAsyncResult<number>>
```
> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'getTotalUnreadCount start');
IMEngine.getInstance()
  .getTotalUnreadCount()
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getTotalUnreadCount result :%{public}d', JSON.stringify(result));

  })
```
## 4.18 获取本地批量会话的未读数之和
```ts
/**
 * 获取本地批量会话的未读数之和
 * @param conIds 会话标识数组
 * @returns 未读数
 */
public getTotalUnreadCountByIds(conIds: List<ConversationIdentifier>): Promise<IAsyncResult<number>>
```

> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'getTotalUnreadCountById start');
IMEngine.getInstance()
  .getTotalUnreadCountByIds(list)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getTotalUnreadCountById result :%{public}d', JSON.stringify(result));
  })
```
## 4.19 获取单个会话的未读数
```ts
/**
 * 获取单个会话的未读数
 * @param conId 会话标识
 * @returns 该会话的未读数
 */
public getUnreadCount(conId: ConversationIdentifier): Promise<IAsyncResult<number>>
```

> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

IMEngine.getInstance().getUnreadCount(conId).then(result => {
  hilog.info(0x0000, 'IM-App', 'getUnreadCount result :%{public}s', JSON.stringify(result));
});
```
## 4.20 清空单个会话未读数
```ts
/**
 * 清空单个会话未读数
 * @param conId 会话标识
 * @returns 结果
 */
public clearMessagesUnreadStatus(conId: ConversationIdentifier): Promise<IAsyncResult<void>>
```
> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

hilog.info(0x0000, 'IM-App', 'clearMessageUnreadStatus start');
IMEngine.getInstance().clearMessagesUnreadStatus(conId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'clearMessageUnreadStatus result %{public}s', JSON.stringify(result));
  })
```
## 4.21 清除单个会话的未读数：按照时间戳清除
```ts
/**
 * 清除单个会话的未读数：按照时间戳清除
 * @param conId 会话标识
 * @param time 时间，清理小于该时间戳的消息未读
 * @returns 结果
 */
public clearMessagesUnreadStatusByTime(conId: ConversationIdentifier,
                                       time: number): Promise<IAsyncResult<void>>
```
> 示例代码
```ts
let conId = new ConversationIdentifier();
conId.conversationType = ConversationType.Private;
conId.targetId = "TestTargetId"; // 按需填写实际的会话 id

let time = Date.now();

hilog.info(0x0000, 'IM-App', 'clearMessagesUnreadStatusByTime start');
IMEngine.getInstance().clearMessagesUnreadStatusByTime(conId, time)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'clearMessagesUnreadStatusByTime result %{public}s', JSON.stringify(result));
  })
```
## 4.22 会话未读数，是否包含免打扰会话的未读数
```ts
  /**
   * 会话未读数，是否包含免打扰会话的未读数
   * @param typeList 会话类型数组
   * @param isContainBlocked 是否包含免打扰；true 代表获取所有会话未读数之和； false 代表获取不包含免打扰会话的正常会话未读数之和
   * @returns 未读数
   * @discussion 正常单聊会话 A 的未读数为1，免打扰单聊会话 B 的未读数为 2。true 代表获取两个单聊会话的未读数之和，其结果为 3。false 代表获取正常会话 A 的未读数，结果为 1
   */
public getUnreadCountByTypes(typeList: List<ConversationType>, isContainBlocked: boolean): Promise<IAsyncResult<number>>
```
> 示例代码
```ts
let typeList = new List<ConversationType>();
typeList.add(ConversationType.Private);
typeList.add(ConversationType.Group);
IMEngine.getInstance().getUnreadCountByTypes(typeList, true).then(result => {
  hilog.info(0x0000, 'IM-App', 'getUnreadCountByTypes result :%{public}s', JSON.stringify(result));
});
```
# 5. 聊天室相关接

## 5.1 设置聊天室状态监听
```ts
/**
 * 设置聊天室状态监听
 * @param listener 监听
 */
public setChatroomStatusListener(listener: ChatroomStatusListener): void
```
> 示例代码
```ts
hilog.info(0x0000, 'IM-App', 'setConversationStatusListener start');
let listener: ChatroomStatusListener = {
  onChatroomJoining(roomId: string): void {
    hilog.info(0x0000, 'IM-App', 'onChatroomJoining roomId:%{public}s', roomId);
  },

  onChatroomJoined(roomId: string, info: ChatroomJoinedInfo): void {
    hilog.info(0x0000, 'IM-App', 'onChatroomJoined roomId:%{public}s info:%{public}s', roomId, JSON.stringify(info));
  },

  onChatroomJoinFailed(roomId: string, code: EngineError): void {
    hilog.info(0x0000, 'IM-App', 'onChatroomJoined roomId:%{public}s code:%{public}d', roomId, code);
  },

  onChatroomQuited(roomId: string): void {
    hilog.info(0x0000, 'IM-App', 'onChatroomQuited roomId:%{public}s', roomId);
  },

  onChatroomDestroyed(roomId: string, type: ChatroomDestroyType): void {
    hilog.info(0x0000, 'IM-App', 'onChatroomDestroyed roomId:%{public}s type:%{public}d', roomId, type);
  },
}
IMEngine.getInstance().setChatroomStatusListener(listener);
```
## 5.2 加入已经存在的聊天室
```ts
/**
 * 加入已经存在的聊天室
 * @param roomId 聊天室 ID
 * @param msgCount 消息个数
 * @returns 结果
 * @note 聊天室的创建需要通过 AppServer 调用 IM 服务的 ServerAPI 创建
 */
public joinExistingChatroom(roomId: string, msgCount: number): Promise<IAsyncResult<ChatroomJoinedInfo>>
```
> 示例代码
```ts
let roomId = "TestChatroomId"; // 按需填写实际的聊天室 id
let msgCount = 5;

IMEngine.getInstance().joinExistingChatroom(roomId, msgCount)
  .then(result => {
    MethodCallModelArray.push(MethodCallModel.from("加入已存在的聊天室", "joinExistingChatroom", result));
    hilog.info(0x0000, 'IM-App', 'joinExistingChatroom result ：%{public}s', JSON.stringify(result));
  });
```
## 5.3 退出聊天室
```ts
/**
 * 退出聊天室
 * @param roomId 聊天室 ID
 * @returns 结果
 */
public quitChatroom(roomId: string): Promise<IAsyncResult<void>>
```
> 示例代码
```ts
let roomId = "TestChatroomId"; // 按需填写实际的聊天室 id

IMEngine.getInstance().quitChatroom(roomId)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'quitChatroom result ：%{public}s', JSON.stringify(result));
  });
```
## 5.4 获取聊天室信息
```ts
/**
 * 获取聊天室信息
 * @param roomId 聊天室 ID
 * @param option 配置
 * @returns 聊天室信息
 * @see ICountOption
 */
public getChatroomInfo(roomId: string, option: ICountOption): Promise<IAsyncResult<ChatroomInfo>>
```
> 示例代码
```ts
let roomId = "TestChatroomId"; // 按需填写实际的聊天室 id

let option: ICountOption = {
  count: 10,
  order: Order.Descending
}

IMEngine.getInstance().getChatroomInfo(roomId, option)
  .then(result => {
    hilog.info(0x0000, 'IM-App', 'getChatroomInfo result ：%{public}s', JSON.stringify(result));
  });
  ```