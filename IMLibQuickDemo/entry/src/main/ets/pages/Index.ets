import { EnvDefine } from './EnvDefine';
import App from '@system.app';
import { promptAction } from '@kit.ArkUI';
import {
  AreaCode,
  ConnectionStatus,
  ConversationIdentifier,
  ConversationType,
  EngineError,
  IMEngine,
  InitOption,
  ISendMsgOption,
  Message,
  ReceivedInfo,
  TextMessage
} from '@rongcloud/imlib';
import hilog from '@ohos.hilog';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Column() {
      Button("初始化 SDK并设置监听", { type: ButtonType.Normal }).
        fontSize(25).
        margin(10).
        fontWeight(FontWeight.Bold).
        onClick(() => {
          this.init();
        })

      Button("连接", { type: ButtonType.Normal }).fontSize(25).margin(10).fontWeight(FontWeight.Bold).onClick(() => {
        this.connect();
      })

      Button("发送文本消息", { type: ButtonType.Normal }).
        fontSize(25).
        margin(10).
        fontWeight(FontWeight.Bold).
        onClick(() => {
          this.sendMessage();
        })
    }.height('100%').width('100%')
  }

  private init() {
    let appKey = EnvDefine.appKey;

    if (!appKey) {
      promptAction.showToast({ message: "初始化失败：appKey 为空", duration: 1000 })
      return;
    }

    let initOption = new InitOption();
    // initOption.areaCode = AreaCode.SG; 指定对应的数据中心
    IMEngine.getInstance().init(getContext(this), appKey, initOption);

    // 接收消息回调
    IMEngine.getInstance().setMessageReceivedListener((msg: Message, info: ReceivedInfo) => {
      hilog.info(0x0000, 'IM-App', 'setMessageReceivedListener msg:%{public}s info:%{public}s', JSON.stringify(msg),
        JSON.stringify(info));
    })
  }

  private connect() {
    let token = EnvDefine.imToken;
    if (!token) {
      promptAction.showToast({ message: "初始化失败：token 为空", duration: 1000 })
    }

    IMEngine.getInstance().setConnectionStatusListener((status: ConnectionStatus) => {
      hilog.info(0x0000, 'IM-App', 'setConnectionStatusListener onChanged status:%{public}d', status);
    });

    IMEngine.getInstance().connect(token, 10).then(result => {
      if (EngineError.Success === result.code) {
        // 连接成功
        let userId = result.userId;
        hilog.info(0x0000, 'IM-App', 'connect success:%{public}s', userId);
        return;
      }

      if (EngineError.ConnectTokenExpired === result.code) {
        // Token 过期，从 APP 服务请求新 token，获取到新 token 后重新 connect()
      } else if (EngineError.ConnectionTimeout === result.code) {
        // 连接超时，弹出提示，可以引导用户等待网络正常的时候再次点击进行连接
      } else {
        //其它业务错误码，请根据相应的错误码作出对应处理。
      }
    });
  }

  private sendMessage() {
    // 创建会话标识，代表需要往对应回话发送消息
    let conId = new ConversationIdentifier();
    conId.conversationType = ConversationType.Private;
    conId.targetId = "2";

    // 创建文本消息
    let txtMsg = new TextMessage();
    txtMsg.content = "文本消息，来自鸿蒙";

    // 发送消息

    let msg = new Message(conId, txtMsg);
    let option: ISendMsgOption = {}

    IMEngine.getInstance().sendMessage(msg, option, (message: Message) => {
      // 消息入库回调
      hilog.info(0x0000, 'IM-App', 'sendMessage db msg:%{public}s', JSON.stringify(message));
    }).then(result => {
      // 消息发送结果回调
      if (EngineError.Success !== result.code) {
        // 发送消息失败，具体原因见 result.code
        return;
      }
      // 发送消息成功，获取消息对象
      let message = result.data as Message;
      hilog.info(0x0000, 'IM-App', 'sendMessage success msg:%{public}s', JSON.stringify(message));
    });

  }
}