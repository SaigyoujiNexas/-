# 在传统View与Compose之间进行衔接

在XML的View体系中，Compose的入口点为ComposeView。在Compose中，传统View的入口点为AndroidView。

通过修改XML，与一部分代码，即可实现与Compose的衔接。

```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/root"
    android:layout_width="match_parent"
    android:orientation="vertical"
    android:layout_height="match_parent">
    <androidx.compose.ui.platform.ComposeView
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:id="@+id/compose_root">
    </androidx.compose.ui.platform.ComposeView>
</LinearLayout>
```

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        binding.composeRoot.setContent{
            AndroidView(factory = {context ->
                WebView(context).apply{
                    settings.javaScriptEnabled = true
                    webViewClient = WebViewClient()
                    loadUrl("https://www.baidu.com")
                }
            }, modifier = Modifier.fillMaxSize())
        }
}
```

# Modifler

```kotlin
@Composable
fun Hello(){
    Row{
        Image(painterResource(id = R.drawable.avatar),
             contentDescription = null,
             modifier = Modifier.size(60.dp)
             .clip(CircleShaape))
        Spacer(modifier = Modifier.width(10.dp))
        Image(painterResource(id = R.drawable.avatar),
             contentDescription = null,
             modifier = Modifier.size(60.dp)
             .clip(RoundedCornerShape(10.dp)))
    }
}
```

Modifier.size 提供了重载方法，可以设置width和height.

```kotlin
Modifier.size(width = 120.dp, height = 30.dp)
```

background 可以设置背景颜色

```kotlin
Modifier.background(Color.Green)
```

Brush 允许了渐变色的颜色格式。

```kotlin
Modifier.background(Brush.verticalGradient(
	colors = listOf(
    	Color.Red,
        Color.Green,
        Color.Blue
    )
))
```



被LayoutScopeMarker注解的layout会有一个固定的作用域。 

Modifier可以绘制边框

```kotlin
Modifier.border(1.dp, color = Color.Black, shape = CircleShape)
```

Modifier.offset实现了控件的移动。

## 实现原理

```kotlin
interface Modifier{
    fun  <R> foldIn(initial: R, operation: (R, Element) -> R): R
    fun <R> foldOut(initial: R, operation:(Element, R) -> R): R
    fun any(predicate: (Element) -> Boolean): Boolean
    fun all(predicate: (Element) -> Boolean): Boolean
    infix fun then(other: Modifier): Modifier = ....
    interface Element: Modifier{...}
    //default implement
    companion object: Modifier{
        override fun <R> foldIn(initial: R, operation(R, Element) -> R):R = initial
        override fun <R> foldOut(initial: R, operation(Element, R) -> R): R = initial
        override fun any(predicate: (Element) -> Boolean): Boolean = false
        override fun all(predicate: (Element) -> Boolean): Boolean = true
        override infix fun then(other: Modifier): Modifier = other
        override fun toString() = "Modifier"
    }
}
```

companion object 内部封装着一个默认的空modifier，对于这个then

```kotlin
internal object BoxScopeInstance: BoxScope{
    @Stable
    override fun Modifier.align(alignment: Alignment) = this.then(
    	BoxChildData(
        	alignment = alignment,
            matchParentSize = false,
            inspectorInfo = debugInspectorInfo{
                name = "align"
                value = alignment
            }
        )
    )
}
```

对于BoxScope，那个other就是then内部的全部代码。

Modifier实际是一个接口， 其有三个具体实现，分别是Modifier伴生对象，Modifier.Element和CombinedModifier。

ConbinedModifier用于链接Modifier链中的每个Modifier对象；Modifier.Element代表具体的修饰符。

```kotlin
fun Modifier.size(size: Dp) = this.then(
	SizeModifier(...)
)
```

接口的默认实现:

```kotlin
infix fun then(other: Modifier): Modifier = 
	if(other == Modifier) this else CombinedModifier(this, other)
```

CombinedModifier: 

```kotlin
class CombinedModifier(
	private val outer: Modifier,
    private val inner: Modifier
): Modifier{
    override fun <R> foldIn(initial: R, operation: (R, Element) -> R): R = inner.foldIn(outer.foldIn(initial, operation), operation)
    override fun <R> foldOut(initial: R, operation: (Element, R) -> R): R = outer.foldOut(inner.foldOut(initial, operation), operation)
    override fun any(predicate: (Modifier.Element) -> Boolean): Boolean = outer.any(predicate) || inner.any(predicate)
    override fun all(predicate: (Modifier.Element) -> Boolean): Boolean = 
    outer.all(predicate) && inner.all(predicate)
    ...
}
```

类似于协程中

```kotlin
@SinceKotlin("1.3")
internal class CombinedContext(
	private val left: CoroutineContext,
    private val element: Element
): CoroutineContext, Serializable{
    
    override fun <E: Element> get(key: Key<E>) : E?{
        var cur = this
        while(true){
            cur.element[key]?.let{return it}
            val next = cur.left
            if(next is CombinedContext){
                cur = next
            }else{
                return next[key]
            }
        }
    }
}
```

相当于把element组合进这个left中。

```kotlin
listOf(1, 2, 3).fold(StringBuilder()){
    acc, e ->
    acc.append(e)
    acc
}
```

Modifier.Element的foldIn的默认实现：

```kotlin
interface Element: Modifier{
    override fun <R> foldIn(initial: R, operation: (R, Element) -> R): R = operation(initial, this)
    
    override fun <R> foldOut(initial: R, operation: (Element, R) -> R): R = operation(this, initial)
    override fun any(predicate: (Element) -> Boolean): Boolean = predicate(this)
    override fun all(prdicate: (Element) -> Boolean): Boolean = predicate(this)
}
```

foldIn从外向内折叠，foldOut从内向外折叠。

SizeModifier实现了LayoutModifier接口，而LayoutModifier是Modifier.Element的子接口。

![image-20220922170028630](https://s2.loli.net/2022/09/22/PGLfaNKE8HwrRg2.png)

像LayoutModifier这类直接继承Modifier.Element的接口，可以称之为Base Modifier。

![image-20220922170912368](https://s2.loli.net/2022/09/22/6L8bKvxklz2YA3y.png)

### 链的链接

CombinedModifier连接的两个Modifier分别存储在outer和inner中。

假设从Modifier伴生对象为起点进行构造

```kotlin
Modifier.size(100.dp)
```

![image-20220922170509421](https://s2.loli.net/2022/09/22/CjuBkFwmdNQ62MP.png)

然后添加background

```kotlin
Modifier.size(100.dp)
	.background(Color.Red)
```

![image-20220922170635270](https://s2.loli.net/2022/09/22/uXAOCHPjmExSZTN.png)

再添加一个padding

```kotlin
Modifier
	.size(100.dp)
	.background(Color.Red)
	.padding(10.dp)
```

![image-20220922170834274](https://s2.loli.net/2022/09/22/BySlJo62LVXxD5t.png)

foldIn正向遍历，foldOut逆向遍历

在Layout中的实现中，Modifier实例被传入一个materializerOf的方法

```kotlin
@UiComposable
@Composable
inline fun Layout(
	content: @Composable @UiComposable ()->Unit,
    modifier: Modifier = Modifier,
    measurePolicy: MeasurePolicy
){
    val density = LocalDensity.current
    val layoutDirection = LocalLayoutDirection.current
    val viewConfiguration = LocalViewConfiguration.current
    ReusableComposeNode<ComposeUiNode, Applier<Any>>(
    	factory = ComposeUiNode.Constructor,
        update = {
            set(measurePolicy, ComposeUiNode.SetMeasurePolicy)
            set(density, ComposeUiNode.SetDensity)
            set(layoutDirection, ComposeUiNode.SetLayoutDirection)
            set(viewConfiguration, ComposeUiNode.SetViewConfiguration)
        },
        skippableUpdate = materializerOf(modifier),
        content = content
    )
}
...
internal fun materializerOf(
	modifier: Modifier
):@Composable SkippableUpdater<ComposeUiNode>.() -> Unit = {
    val materialized = currentComposer.materialize(modifier)
    update{
        set(materialized, ComposeUiNode.SetModifier)
    }
}

```

```kotlin
fun Composer.materialize(modifier: Modifier): Modifier{
    if(modifier.all{
        it !is ComposedModifier && it !is FocusEventModifier && it !is FocusRequesterModifier
    }){
        return modifier
    }
    
     startReplaceableGroup(0x48ae8da7)
    
    val result = modifier.foldIn<Modifier>(Modifier){acc, element -> 
       acc.then(
           if(element is ComposedModifier){
               val factory = element.factory as Modifier.(Composer, Int) -> Modifier
               val composedMod = factory(Modifier, this, 0)
               materialize(composedMod)
           }else{
               // onFocusEvent is implemented now with ModifierLocals and SideEffects, but
                // FocusEventModifier needs to have composition to do the same. The following
                // check for FocusEventModifier is only needed until the modifier is removed.
               var newElement: Modifier = element
               if(element is FocusEventModifier){
                   val factory = WrapFocusEventModifier
                   	as (FocusEventModifier, Composer, Int)-> Modifier
                   newElement = newElement.then(factory(element, this, 0))
               }
               if(element is FocusRequesterModifier){
                   val factory = WrapFocusRequesterModifier
                   	as (FocusRequesterModifier, Composer, Int) -> Modifier
                   newElement = bewElement.then(factory(element, this, 0))
               }
               newElement
           }
       )                                                    
    }
    endReplaceableGroup()
    return result
}

```

当Modifier链中包含ComposedModifier时，也会在这里被摊平，将工厂生产Modifier加入到链中，最终链中将不会存在ComposedModifier。

foldOut遍历生成LayoutNodeWrapper链来间接影像组件的测量布局和渲染。

# 基础组件

## Text

```kotlin
fun Text(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    fontSize: TextUnit = TextUnit.Unspecified,
    fontStyle: FontStyle? = null,
    fontWeight: FontWeight? = null,
    fontFamily: FontFamily? = null,
    letterSpacing: TextUnit = TextUnit.Unspecified,
    textDecoration: TextDecoration? = null,
    textAlign: TextAlign? = null,
    lineHeight: TextUnit = TextUnit.Unspecified,
    overflow: TextOverflow = TextOverflow.Clip,
    softWrap: Boolean = true,
    maxLines: Int = Int.MAX_VALUE,
    onTextLayout: (TextLayoutResult) -> Unit = {},
    style: TextStyle = LocalTextStyle.current
) {

    val textColor = color.takeOrElse {
        style.color.takeOrElse {
            LocalContentColor.current.copy(alpha = LocalContentAlpha.current)
        }
    }
    // NOTE(text-perf-review): It might be worthwhile writing a bespoke merge implementation that
    // will avoid reallocating if all of the options here are the defaults
    val mergedStyle = style.merge(
        TextStyle(
            color = textColor,
            fontSize = fontSize,
            fontWeight = fontWeight,
            textAlign = textAlign,
            lineHeight = lineHeight,
            fontFamily = fontFamily,
            textDecoration = textDecoration,
            fontStyle = fontStyle,
            letterSpacing = letterSpacing
        )
    )
    BasicText(
        text,
        modifier,
        mergedStyle,
        onTextLayout,
        overflow,
        softWrap,
        maxLines,
    )
}

```

可以为text参数传入要显示的文字内容，Compose也提供了stringResource通过R资源文件获取字符串。

```kotlin
@Composable
@ReadOnlyComposable
fun stringResource(@StringRes id: Int, vararg formatArgs: Any): String{
    val resouces = resources()
    return resouces.getString(id, *formatArgs)
}

@Composable
@ReadOnlyComposable
fun stringArrayResource(@ArrayRes id: Int) : Array<String>{
    val resources = resouces();
    return resources.getStringArray(id)
}
```



### style 文字样式

style接受一个TextStyle类型，TextStyle包含一系列设置文字样式的字段。

```kotlin
Text(
	text = "Hello, world\n" + "Goodbye world"
)
Text(
	text = "Hello world\n" + "Goodbye world",
    style = TextStyle(
    	fontSize = 25.sp,
        fontWeight = FontWeight.Bold,
        background = Color.Cyan,
        lineHeight = 35.sp
    )
)
Text(
	text =  "Hello world",
    style = TextStyle(
    	color = Color.Gray,
        letterSpacing = 4.sp
    )
)

Text(
	text = "Hello World",
    style = TextStyle(
    textDecoration = TextDecoration.LineThrough //delete line
    ) 
)
```

TextStyle提供了类似data class 的copy方法。

TextDecoration可以为文字添加下划线或者删除线，FontStyle可以设置文字是否是斜体。

MaterialTheme.typography.h6这一类的为内置的TextStyle。

### maxLine文字参数

```kotlin
Text(
	text = "Hello world, I am developing my App interface by Jetpack Compose",
    style = MaterialTheme.typography.body1
)

Text(
	text = "Hello world, I am developing my App interface by Jetpack Compose",
    style = MaterialTheme.typography.body1,
    maxLine = 1			//文本截断
)
Text(
	text = "Hello world, I am developing my App interface by Jetpack Compose",
    style = MaterialTheme.typography.body1,
    maxLines = 1,
    overflow = TextOverflow.Ellipsis		//省略号
)
```

### fontFamily 字体风格

```kotlin
Text("Hello, world")
Text("Hello, world", fontFamily = FontFamily.Monospace)
Text("Hello, world", fontFamily = FontFamily.Cursive)
```

### AnnotatedString 多样式文字

应用于对于一些需要对局部内容做特别格式的场景。

```kotlin
fun TextDemo11(){
    val text = buildAnnotatedString { 
        append("勾选即代表同意")
        pushStringAnnotation(tag = "tag",
        annotation = "一个用户协议哼哼哼啊啊啊啊啊啊")
        withStyle(
            style = SpanStyle(
                color = Color(0xFF0E9FF2),
                fontWeight = FontWeight.Bold)){
            append("用户协议")
        }
        pop()
    }
    ClickableText(text = text, onClick = { offset ->
        text.getStringAnnotations(tag = "tag", start = offset, end = offset)
            .firstOrNull()?.let{
                Log.d(TAG, "你已经点到 ${it.item} 啦")
            }
    })
}
```

![img](https://jetpackcompose.cn/assets/images/text13-46d02546efea856f04fb14b9915b36eb.gif)

AnnotatedString数据类除了文本值，还包含了一个SpanStyle和ParagraphyStyle的Range列表，SpanStyle用于描述字串的文字样式，ParagraphyStyle用于描述字串段落样式，Range确定字串的范围。

### SelectionContainer 选中文字

Text默认不能被选择

Compose的SelectionContainer组件就支持了对包裹的Text进行选中

```kotlin
SelectionContainer{
    Text("I am text that can be copied")
}
```

## TextField

TextField是文本输入框，有两种风格，一个是默认，即filled，一个是OutLinedTextField。

```kotlin
@Composable
fun TextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    textStyle: TextStyle = LocalTextStyle.current,
    label: @Composable (() -> Unit)? = null,
    placeholder: @Composable (() -> Unit)? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    isError: Boolean = false,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions(),
    singleLine: Boolean = false,
    maxLines: Int = Int.MAX_VALUE,
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
    shape: Shape =
        MaterialTheme.shapes.small.copy(bottomEnd = ZeroCornerSize, bottomStart = ZeroCornerSize),
    colors: TextFieldColors = TextFieldDefaults.textFieldColors()
)
```

`Filled TextField` 和 `Outlined TextField` 都是按照 `Material Design` 来设计的，所以里面的一些间距是固定的，当你使用 `Modifier.size()` 等之类的方法尝试去修改它很可能会有以下的效果

```kotlin
TextField(
	value = text,
	onValueChange = {
		text = it
	},
	modifier = Modifier.height(20.dp)
)
```

![img](https://jetpackcompose.cn/assets/images/demo8-860efbda627f882b86e4e0afb1e5753c.png)

如果你想自定义一个 `TextField` 的高度，以及其他的自定义效果，你应该使用 [BasicTextField](https://jetpackcompose.cn/docs/elements/textfield#basictextfield)

一个简单的 `TextField` 使用的例子是这样的：

```kotlin
@Composable
fun TextFieldDemo(){
    var text by remember{ mutableStateOf("")}
    
    TextField(
        value = text, 
        onValueChange = {
            text = it
        })
}
```

![img](https://jetpackcompose.cn/assets/images/demo-0c8b4454e12a55fab5525d43615bd4bf.gif)

### singleLine参数

可以将TextField设置为只有一行，同时maxLines无效。

```kotlin
@Composable
fun TextFieldDemo(){
    var text by remember{mutableStateOf("")}
    TextField(
    value = text,
    onValueChange = {
        text = it
    },
    singleLine = true
    )
}
```

### lable 标签

```kotlin
@Composable
fun TextFieldDemo() {
    var text by remember{ mutableStateOf("")}

    Column(
        modifier = Modifier
            .fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        TextField(
            value = text,
            onValueChange = {
                text = it
            },
            singleLine = true,
            label = {
                Text("邮箱")
            }
        )
    }
}
```

![img](https://jetpackcompose.cn/assets/images/demo2-271402c2e591c30c857cb9cd43e94ee9.gif)

### leadingIcon 参数

leadingIcon接收一个**@Composable**的`lambda`表达式 

```kotlin
TextField(
	value = text,
	onValueChange = {
        text = it
    },
    leadingIcon = {
        Icon(Icons.Filled.Search, null)
    },
)
```

![image-20220924133344988](https://s2.loli.net/2022/09/24/f4WPMIsX6J3GvOg.png)

```kotlin
TextField(
	value = text,
    onValueChange = {
        text = it
    },
    leadingIcon = {
        Text("联系人")
    }
)
```

![image-20220924133531479](https://s2.loli.net/2022/09/24/ZLXrlSoJcfGsqv1.png)

### trailingIcon参数

`trailingIcon` 参数可以在 `TextField` 尾部布置 `lambda` 表达式所接收到的东西

```kotlin
TextField(
	value = text,
    onValueChange = {
        text = it
    },
    trailingIcon = {
        Text("@163.com")
    }
)
```

![image-20220924133652689](https://s2.loli.net/2022/09/24/M7zNnEdR9ufHAwo.png)

```kotlin
trailingIcon = {
    IconButton(onclick = {
        /*TODO: send the message*/
    }){
        Icon(Icons.Filled.Send, null)
    }
}
```

![image-20220924133817044](https://s2.loli.net/2022/09/24/GQFbVDuW2pJqkHI.png)

### Color 参数

```kotlin
@Composable
fun textFieldColors(
    // 输入的文字颜色
    textColor: Color = LocalContentColor.current.copy(LocalContentAlpha.current),

    // 禁用 TextField 时，已有的文字颜色
    disabledTextColor: Color = textColor.copy(ContentAlpha.disabled),

    // 输入框的背景颜色，当设置为 Color.Transparent 时，将透明
    backgroundColor: Color = MaterialTheme.colors.onSurface.copy(alpha = BackgroundOpacity),

    // 输入框的光标颜色
    cursorColor: Color = MaterialTheme.colors.primary,

    // 当 TextField 的 isError 参数为 true 时，光标的颜色
    errorCursorColor: Color = MaterialTheme.colors.error,

    // 当输入框处于焦点时，底部指示器的颜色
    focusedIndicatorColor: Color = MaterialTheme.colors.primary.copy(alpha = ContentAlpha.high),

    // 当输入框不处于焦点时，底部指示器的颜色
    unfocusedIndicatorColor: Color = MaterialTheme.colors.onSurface.copy(alpha = UnfocusedIndicatorLineOpacity),

    // 禁用 TextField 时，底部指示器的颜色
    disabledIndicatorColor: Color = unfocusedIndicatorColor.copy(alpha = ContentAlpha.disabled),

    // 当 TextField 的 isError 参数为 true 时，底部指示器的颜色
    errorIndicatorColor: Color = MaterialTheme.colors.error,

    // TextField 输入框前头的颜色
    leadingIconColor: Color = MaterialTheme.colors.onSurface.copy(alpha = IconOpacity),

    // 禁用 TextField 时 TextField 输入框前头的颜色
    disabledLeadingIconColor: Color = leadingIconColor.copy(alpha = ContentAlpha.disabled),

    // 当 TextField 的 isError 参数为 true 时 TextField 输入框前头的颜色
    errorLeadingIconColor: Color = leadingIconColor,

    // TextField 输入框尾部的颜色
    trailingIconColor: Color = MaterialTheme.colors.onSurface.copy(alpha = IconOpacity),

    // 禁用 TextField 时 TextField 输入框尾部的颜色
    disabledTrailingIconColor: Color = trailingIconColor.copy(alpha = ContentAlpha.disabled),

    // 当 TextField 的 isError 参数为 true 时 TextField 输入框尾部的颜色
    errorTrailingIconColor: Color = MaterialTheme.colors.error,

    // 当输入框处于焦点时，Label 的颜色
    focusedLabelColor: Color = MaterialTheme.colors.primary.copy(alpha = ContentAlpha.high),

    // 当输入框不处于焦点时，Label 的颜色
    unfocusedLabelColor: Color = MaterialTheme.colors.onSurface.copy(ContentAlpha.medium),

    // 禁用 TextField 时，Label 的颜色
    disabledLabelColor: Color = unfocusedLabelColor.copy(ContentAlpha.disabled),

    // 当 TextField 的 isError 参数为 true 时，Label 的颜色
    errorLabelColor: Color = MaterialTheme.colors.error,

    // Placeholder 的颜色
    placeholderColor: Color = MaterialTheme.colors.onSurface.copy(ContentAlpha.medium),

    // 禁用 TextField 时，placeholder 的颜色
    disabledPlaceholderColor: Color = placeholderColor.copy(ContentAlpha.disabled)
)
```

调用方法:

```kotlin
TextField(
	value = text,
    onValueChange = {
        text = it
    },
    leadingIcon = {
        Icon(Icons.Filled.Search, null)
    },
    colors = TextFieldDefaults.textFieldColors(
    	textColor = Color(0xFF0079D3),
        backgroundColor = Color.Transparent
    )
)
```

![img](https://jetpackcompose.cn/assets/images/demo3-432011b11a60ff3f1925b28952acc4ff.gif)



### visualTransformation 参数

`visualTransformation` 可以帮助我们应用输入框的显示模式

```kotlin
var text by remember{mutableStateOf("")}
var passwordHidden by remember{mutableStateOf(false)}

TextField(
	value = text,
    onValueChange = {
        text = it
    },
    trailingIcon = {
        IconButton(
        	onClick = {
                passwordHidden = !passwordHidden
            }
        ){
            Icon(painterResource(id = R.drawable.visibility), null)
        }
    },
    label = {
        Text("密码")
    },
    visualTransformation = if(passwordHidden) PasswordVisualTransformation() else VisualTransformation.None
)
```

![img](https://jetpackcompose.cn/assets/images/demo5-bd4fb93fcfa59d27d019d73d053e9602.gif)

## BasicTextField

```kotlin
@Composable
fun BasicTextField(
  value: String,
  onValueChange: (String) -> Unit,
  modifier: Modifier = Modifier,
  enabled: Boolean = true,
  readOnly: Boolean = false,
  textStyle: TextStyle = TextStyle.Default,
  keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
  keyboardActions: KeyboardActions = KeyboardActions.Default,
  singleLine: Boolean = false,
  maxLines: Int = Int.MAX_VALUE,
  visualTransformation: VisualTransformation = VisualTransformation.None,
  onTextLayout: (TextLayoutResult) -> Unit = {},
  // 当输入框内文本触发更新时候的回调，包括了当前文本的各种信息
  interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
  cursorBrush: Brush = SolidColor(Color.Black),
  // 输入框光标的颜色
  decorationBox: @Composable (innerTextField: @Composable () -> Unit) -> Unit =
    @Composable { innerTextField -> innerTextField() }
  // 是一个允许在 TextField 周围添加修饰的 @Composable lambda
  // 我们需要在布局中调用 innerTextField() 才能完成 TextField 的构建
)
```

使用BasicTExtField可以拥有更高的自定义度

### 简单使用

```kotlin
@Composable
fun BasicTextFieldTest(){
    var text by remember {
        mutableStateOf("")
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFD3D3D3)),
        contentAlignment = Alignment.Center
    ){
        BasicTextField(
            value = text,
            onValueChange = {
                text = it
            },
            modifier = Modifier
                .background(Color.White, CircleShape)
                .height(35.dp)
                .fillMaxWidth(),
            decorationBox = { innerTextField ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(horizontal = 10.dp)
                ){
                    IconButton(
                        onClick = {}
                    ){
                        Icon(Icons.Filled.Mood, null)
                    }
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.CenterStart
                    ){
                        innerTextField()
                    }
                    IconButton(
                        onClick = {}
                    ){
                        Icon(Icons.Filled.Send, null)
                    }
                }
            }
        )
    }

}
```

![img](https://jetpackcompose.cn/assets/images/demo6-f5f3cf3a81d82dee49cfd60c74bdaed3.gif)



### 其他效果

```kotlin
@Composable
fun CustomBasicTextField(){
    var text by remember {
        mutableStateOf("")
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFD3D3D3)),
        contentAlignment = Alignment.Center
    ){
        BasicTextField(
            value  = text,
            onValueChange = {
                text = it
            },
            modifier = Modifier
                .background(Color.White)
                .fillMaxWidth(),
            decorationBox = { innerTextField ->
                Column(
                    modifier = Modifier.padding(vertical = 10.dp)
                ){
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ){
                        IconButton(onClick = {}){Icon(Icons.Filled.Mood, null)}
                        IconButton(onClick = {}){Icon(Icons.Filled.Gif, null)}
                        IconButton(onClick = {}){Icon(Icons.Filled.Shortcut, null)}
                        IconButton(onClick = {}){Icon(Icons.Filled.More, null)}
                    }
                    Box(
                        modifier = Modifier.padding(horizontal = 10.dp)
                    ){
                        innerTextField()
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.End
                    ){
                        TextButton(onClick = {/*TODO*/}){
                            Text("发送")
                        }
                        Spacer(Modifier.padding(horizontal = 10.dp))
                        TextButton(onClick  ={/*TODO*/}){
                            Text("关闭")
                        }
                    }
                }
            }
        )
    }
}
```

![img](https://jetpackcompose.cn/assets/images/demo9-257c78b25a14f3a8a76d9aa548a95e4a.png)

### 实现bilibili样式的搜索框

```kotlin
@Composable
fun BilibiliSearchBar(){
    var text by remember{
        mutableStateOf("")
    }
    Box(
        modifier = androidx.compose.ui.Modifier
            .fillMaxSize()
            .background(Color(0xFFD3D3D3)),
        contentAlignment = Alignment.Center
    ){
        BasicTextField(
            value = text,
            onValueChange = {
                text = it
            },
            decorationBox = { innerTextField ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .padding(vertical = 2.dp, horizontal = 8.dp)
                ) {
                    Icon(Icons.Filled.Search, "search")
                    Box(
                        modifier = Modifier
                            .padding( horizontal = 10.dp)
                            .weight(1f),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if(text.isEmpty()) {
                            Text(
                                text = "输入点东西看看吧~", 
                                style = TextStyle(
                                color = Color(0, 0, 0, 128)
                                )
                            )
                        }
                        innerTextField()
                    }
                    if(text.isNotEmpty()){
                        IconButton(
                            onClick = {text = ""},
                            modifier = Modifier.size(16.dp)
                        ){
                            Icon(Icons.Filled.Close, "cancel")
                        }
                    }
                }
            },
            modifier = Modifier
                .padding(horizontal = 10.dp)
                .background(Color.White, CircleShape)
                .height(30.dp)
                .fillMaxWidth(),
        )
    }
}
```

![image-20220924164627042](https://s2.loli.net/2022/09/24/UTJ2Qv8PxmjIbAM.png)

## FloatingActionButton

```kotlin
@OptIn(markerClass = [ExperimentalMaterialApi])
@Composable
fun FloatingActionButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
    shape: Shape = MaterialTheme.shapes.small.copy(CornerSize(percent = 50)),
    backgroundColor: Color = MaterialTheme.colors.secondary,
    contentColor: Color = contentColorFor(backgroundColor),
    elevation: FloatingActionButtonElevation = FloatingActionButtonDefaults.elevation(),
    content: () -> Unit
): @OptIn(markerClass = [ExperimentalMaterialApi]) @Composable Unit
```

`FAB`通常和一个`Icon`一起使用，或者是带文字扩展的ExtendedFloatingActionButton

```kotlin
FloationActionButton(onClick = {}){
    Icon(Icons.Filled.Favorite, null)
}
```

```kotlin
ExtendedFloatingActionButton(
	icon = {Icon(Icons.Filled.Favorite, null)},
    text = {Text("添加到我喜欢的")}
    onClick = {}
)
```

![img](data:image/png;base64,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)

## Icon

Icon显示一系列的小图标，支持三种不同的图片设置

```kotlin
@Composable
fun Icon(
    imageVector: ImageVector, //矢量图
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color
) 

@Composable
fun Icon(
    bitmap: ImageBitmap, //位图
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color
) 

@Composable
fun Icon(
    painter: Painter, // 画笔
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color			//the icon color.
) 
```

```kotlin
Icon(imageVector = ImageVector.vectorResource(
    id = R.drawable.ic_svg, contentDescription = "矢量图资源")
  
Icon(bitmap = ImageBitmap.imageResource(
    id = R.drawable.ic_png), contentDescription = "图片资源")
    
Icon(painter = painterResource(
    id = R.drawable.ic_both), contentDescription = "任意类型资源")
```

使用Icon显示一个具体的图标：

```kotlin
@Composable
fun IconSample(){
    Icon(
    	imageVector = Icons.Filled.Favorite,
        contentDesciption = null,
        tint = Color.Red
    )
}
```

![img](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFEAAAAvCAIAAAAUxbHQAAADoklEQVRoBe1YTSh0URie695LfiZSUhRNfqaRppSVhWISGwvZKbZW2NEsbJiSYsdSWNlZ+StslGwkP4lIsbEgKbIxc+/93jtn5nXudc1355xJzTgnHc/7nPec933Oc8fMkD4/Pz1/bOT9Mb2mXKH5b5gufBY+5+oNiGc7V5216hI+W+8jVyPhc646a9UlfLbeR65GwudcddaqS/hsvY/U0fT0dFNTU2Njo9/vDwQCU1NTJP/u7q69vR1IMrq7uz8+PpyPen9XmpvV/Hzyo/h80vU1yZTHxtTCwsRSUVFeOOx8AhMrsf1vqKOj4/HxkVQ0DAOAJEllZWUDAwOLi4uAgaTnzc3NhoYGukPp8lJpafliJMkTP0ebnJQXFjyvr19LcWTU1sZub20kW8iieWZmZnl5GeqBKphR83dMJ9zc3NAtgod06AZr4+N6JOImM3UOy+t5dXUVxMAAtTAcMVQFHmZMODw8xFakvT3E7oE8N+c+OUVm2po1TYsrNZ9nGEQYwWQmImGGkMb7+/uYlrexgTgB4hdkJ+kYEnTdo2k0x4YVtm3EZBRMtMFRCOgEGifKfVcYv6NUzfw3IdVmy1raPsuyjBrQTHIk7ep33NbWhpX1zk7E8Kg4Y2QxAYAsI80M0tYMlXw+H8gGgOIR0KQNh0IhYMgwenuT0Hw2nDGyyQTD70eOB7Bo3t7eJiVpM4ls4GkS8fDwsK1LfWLiR4dpY3GbJMXOzzHiASzvVVBvZ2dndHSUuA0h0UYDGkPadfLDBvA41IICi8m44AS0tTW9v99pJW2OxWco0tPTEwwGQSpgm2CaJPji4sKxr+jbm8mjqzaMeyRJb23NlGCzCNvnMNJPV1fXw8MDcRuVwxKNj46OysvLsX87eH5Wq6vtpDU26upiV1dWjiti9JnU3N3dra+vB4VEJMzA0/jg4CCVYMiuqIjd35un0W6bcWIYgUBmBcO5XJph/9bWFr4JgeFEMPCAT05OKisrE73//Muoqoq+vDiuG6FQ7OzMcYmH5NUMtVdWVvr6+kAtEQyzoijHx8fFxcVuO/N6o09PHlWl8/XBwVjyDYLm+XEGNEMTs7OzIyMjpBuQenp66vV602uutDQK36VKSsguLRzWlpbSO8F1NtffMFuV9fX1+fl5+ruELcFNqNbUaJGIPjTkJpktJ5Oa2Tr4/V2ZebZ/v2+eikIzz+1lz17hc/Z4xdOp8Jnn9rJnr/A5e7zi6VT4zHN72bP3H/bckRYF8zOuAAAAAElFTkSuQmCC)

例子中的 Favorite 是一个 Filled 风格的图标，Material 包每个图标都提供了五种风格可供使用，除了 Filled，还包括 Outlined，Rounded，Sharp，Two tone 等，都可以通过 Icons.xxx.xxx 的方式调用。这五种风格在一些设计上的侧重点不同，如下图所示：

| Icon 类型 | 特点         | 代表示例                                                     |
| --------- | ------------ | ------------------------------------------------------------ |
| Outlined  | 勾勒轮廓     | ![img](https://jetpackcompose.cn/assets/images/outlined-ee7cf67c4bf8c944dca26b97db6f4ac2.png) |
| Filled    | 图形填充     | ![img](https://jetpackcompose.cn/assets/images/filled-762fa08aaec8b4c78fff4a448fa29d36.png) |
| Rounded   | 端点均为圆角 | ![img](https://jetpackcompose.cn/assets/images/rounded-e72afa604ea98dfbc594ca8e87e386b1.png) |
| Sharp     | 端点均为尖角 | ![img](https://jetpackcompose.cn/assets/images/sharp-71fa8ab92b45e5d9fa46463a1626703b.png) |
| TwoTone   | 双色搭配     | ![img](https://jetpackcompose.cn/assets/images/twotone-dd6aa538964b0df7ce637e01904d886e.png) |

如果需要下载所有的Material图标

```groovy
implementation "androidx.compose.material:material-icons-extended:$compose_version"
```

## Button

```kotlin
@OptIn(ExperimentalMaterialApi::class)
@Composable
fun Button(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
    elevation: ButtonElevation? = ButtonDefaults.elevation(),
    shape: Shape = MaterialTheme.shapes.small,
    border: BorderStroke? = null,
    colors: ButtonColors = ButtonDefaults.buttonColors(),
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding,
    content: @Composable RowScope.() -> Unit
)
```

创建一个显示文字的Button:

```kotlin
@Composable
fun ButtonSample(){
    Button(
    	onClick = {}
    ){
        Text(text = "确认")
    }
}
```

content提供了RowScope的作用域。

```kotlin
@Composable
fun ButtonSample(){
    Button(
    	onClick = {}
    ){
        Icon(
        	Icons.Filled.Done,
            "done",
            modifier = Modifier.size(ButtonDefaults.IconSize)
        )
        Spacer(Modifier.size(ButtonDefaults.IconSpacing))
        Text(text = "确认")
    }
}
```

![image-20220924190921281](https://s2.loli.net/2022/09/24/Vhy9J8cuba4RvZm.png)

Button有一个参数InteractionSource，可以监听组件状态

```kotlin
@Composable
fun ButtonSample(){
    val interactionSource = remeber{
        MutableInteractionSource()
    }
    
    val pressState = interactionSource.collectIsPressedAsState()
    val borderColor = if(pressState.value) Color.Green else Color.White
    Button(
    	onClick = {},
        border = BorderStroke(2.dp, color = borderColor),
        interactionSource  = interactionSource
    ){
        Icon(
        	Icons.Filled.Done,
            "done",
            modifier = Modifier.size(ButtonDefaults.IconSize)
        )
        Spacer(Modifier.size(ButtonDefaults.IconSpacing))
        Text(text = "确认")
    }
}
```

Button的onClick在底层是覆盖了Modifier.clickable

### IconButton

实际上是一个Button的简单封装（可点击图标）

```kotlin
@Composable
fun IconButtonSamble(){
    IconButton(
    	onClick = {}
    ){
        Icon(Icons.Filled.Favorite, null)
    }
}
```



# 布局组件

## Box

Box 是一个能将子项依次按照顺序堆叠的布局组件， 类似于RelativeLayout.

```kotlin
Box{
    Box(modifier = Modifier.size(150.dp).background(Color.Green)
    )
    Box(modifier = Modifier.size(80.dp).background(Color.Red)
    )
    Text(
        text = "世界"
    )
}
```

![image-20220904115920998](https://s2.loli.net/2022/09/04/AhR84p9TsiEjxfd.png)

## BottomNavigation

Bottom Navigation Bars 允许在一个应用程序的主要目的地之间移动。

```kotlin
@Composable
fun ScaffoldDemo(){
    var selectedItem by remember {
        mutableStateOf(0)
    }
    val items = listOf("主页", "我喜欢的", "设置")
    Scaffold(topBar = {
        TopAppBar(
            title = {
                    Text("主页")
            },
            navigationIcon = {
                IconButton(onClick = { }) {
                    Icon(imageVector = Icons.Filled.ArrowBack,
                        contentDescription = null)
                }
            }
        )
    },
    bottomBar = {
        BottomNavigation {
            items.forEachIndexed { index, item ->
                BottomNavigationItem(
                    icon = {
                        when(index){
                            0 -> Icon(Icons.Filled.Home, contentDescription = null)
                            1 -> Icon(Icons.Filled.Favorite, contentDescription = null)
                            else -> Icon(Icons.Filled.Settings, contentDescription = null)
                        }
                           },
                    label = { Text(text = item)},
                    selected = selectedItem == index,
                    onClick = { selectedItem = index })
            }
        }
    }) {

    }

}
```

完成效果如图：

![image-20220904173622446](https://s2.loli.net/2022/09/04/AtkWCZFfszIldVn.png)

### 自定义BottomNavigation

```kotlin
@Composable
fun MyBottomNavigation() {

    var selectedItem by remember{ mutableStateOf(0) }

    BottomNavigation(
        backgroundColor = Color.White
    ) {
        for(index in 0..2 ) {
            Column(
                modifier = Modifier
                    .fillMaxHeight()
                    .weight(1f)
                    .clickable(
                        onClick = {
                            selectedItem = index
                        },
                        indication = null,
                        interactionSource = MutableInteractionSource()
                    ),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                NavigationIcon(index, selectedItem)
                Spacer(Modifier.padding(top = 2.dp))
                AnimatedVisibility(visible = index == selectedItem) {
                    Surface(shape = CircleShape, modifier = Modifier.size(5.dp),color = Color(0xFF252527)) { }
                }
            }
        }
    }
}

@Composable
fun NavigationIcon(
    index:Int,
    selectedItem:Int
){
    val alpha = if (selectedItem != index ) 0.5f else 1f

    CompositionLocalProvider(LocalContentAlpha provides alpha) {
        when(index){
            0 -> Icon(Icons.Filled.Home, contentDescription = null)
            1 -> Icon(painterResource(R.drawable.musicnote), contentDescription = null)
            else -> Icon(Icons.Filled.Settings, contentDescription = null)
        }
    }
}
```

## Column

```kotlin
@Composable
inline fun Column(
	modifier: Modifier? = Modifier,
    verticalArrangement: Arrangement.Vertical? = Arrangement.Top,
    horizontalAlignment: Alignment.Horizontal? = Alignment.Start,
    content: (@Composable @ExtensionFunctionType ColumnScope.() -> Unit)?
): Unit
```

简单使用如下：

```kotlin
Column{
    Text(
    	text = "Hello, World!",
        style = MaterialTheme.typography.h6
    )
    Text("Jetpack Compose")
}
```



![image-20220907115737531](https://s2.loli.net/2022/09/07/LheSxD8CVnNZ3Rw.png)

边框效果：

```kotlin
Column(
    modifier = Modifier
    	.border(1.dp, Color.Black)
){
    Text(
    	text = "Hello, World!",
        style = MaterialTheme.typography.h6
    )
    Text("Jetpack Compose")
}
```

![image-20220907115900416](https://s2.loli.net/2022/09/07/Zxj6PlKT8ieka1y.png)

在不给Column指定大小的情况下，Column默认会尽可能小

当指定了高度，就能使用verticalArrangement定位垂直位置

当制定了宽度，就能使用horizontalAlignment定位水平位置

```kotlin
Column(
	modifier = Modifier
    	.border(1.dp, Color.Black)
    	.size(150.dp),
    verticalArrangement = Arrangement.Center
){
    Text(
        text = "Hello, World",
        style = MaterialTheme.typography.h6
    )
    Text("Jetpack Compose")
}
```

![image-20220907120335263](https://s2.loli.net/2022/09/07/md3FiRVXwTqNWu4.png)

设置了Modifier.align属性的子项会优先于Colume的horizontalAlignment参数。

```kotlin
Column(
	modifier = Modifier
    	.border(1.dp, Color.Black)
    	.size(150.dp),
    verticalArrangement = Arrangement.Center
){
    Text(
    	text = "Hello, World",
        style = MaterialTheme.typography.h6,
        modifier = Modifier.align(Alignment.Center)
    )
    Text("Jetpack Compose")
}
```



![image-20220908111724306](https://s2.loli.net/2022/09/08/A8SrGtvu14DJnFz.png)

## ModalBottomSheetLayout

```kotlin
@Composable
@ExperimentalMaterialApi
fun ModalBottomSheetLayout(
	sheetContent: @Composable ColumnScope.() -> Unit,
    modifier: Modifier = Modifier,
    sheetState: ModalBottomSheetState = rememberModalBottomSheetState(ModalBottomSheetValue.Hidden),
    sheetShape: Shape = MaterialTheme.shapes.large,
    sheetElevation: Dp = ModalBottomSheetDefaults.Elevation,
    sheetBackgroundColor: Color = MaterialTheme.colors.surface,
    sheetContentColor: Color = contentColorFor(sheetBackgroundColor),
    scrimColor: Color = ModalBottomSheetDefaults.scrimColor,
    content: @Composable () -> Unit
)
```

![image-20220908171054707](https://s2.loli.net/2022/09/08/BbH3TJplSZCKrL7.png)

ModalBottomSheetLayout可以在App的底部弹出。

```kotlin
fun ModalBottomSheetLayoutTest(){
    val state = rememberModalBottomSheetState(initialValue = ModalBottomSheetValue.Hidden)
    val scope = rememberCoroutineScope()
    ModalBottomSheetLayout(
        sheetState = state,
        sheetContent = {
            Column {
                ListItem(
                    text = { Text("选择分享到哪里吧~") }
                )
                ListItem(
                    text = { Text("github")},
                    icon = {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFF181717)
                        ) {
                            Icon(
                                painterResource(id = R.drawable.github),
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.padding(4.dp)
                            )
                        }
                    },
                    modifier = Modifier.clickable{}
                )
                ListItem(
                    text = {Text("微信")},
                    icon = {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFF07C160)
                        ){
                            Icon(
                                painterResource(id = R.drawable.wechat),
                                null,
                                tint = Color.White,
                                modifier = Modifier.padding(4.dp)
                            )
                        }
                    },
                    modifier = Modifier.clickable{}
                )
            }
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ){
            Button(
                onClick = {scope.launch {state.show()}}
            ){
                Text("点我展开")
            }
        }
    }
}

```

ModalBottomSheet无法处理按下返回键就收起。

可以使用BackHandler处理按下返回键无法收起的问题。

```kotlin
BackHandler(
	enable = (state.currentValue == ModalBottomSheetValue.HalfExpanded ||
             state.currentValue == ModalBottomSheetValue.Expanded),
    onBack = {
        scope.launch{
            state.hide()
        }
    }
)
```

还可以自定义动画时间

```kotlin
state.animateTo(ModalBottomSheetValue.Hidden, tween(1000))
```

弹出同理。

## Row

```kotlin
@Composable
inline fun Row(
	modifier: Modifier? = Modifier,
    horizontalArrangement: Arrangement.Horizontal? = Arrangement.Start,
    verticalAlignment: Alignment.Vertical? = Alignment.Top,
    content: (@Composable @ExtensionFunctionType RowScope.() -> Unit)?
): Unit
```



Row组件将子项从左到右水平排列。

```kotlin
fun RowTest() {
    Surface(
        shape = RoundedCornerShape(8.dp),
        modifier = Modifier
            .padding(horizontal = 12.dp)
            .fillMaxSize(),
        elevation = 10.dp
    ){
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = "Jetpack Compose 是什么？", 
                style = MaterialTheme.typography.h6
            )
            Spacer(modifier = Modifier.padding(vertical = 5.dp))
            Text(text = "Jetpack Compose 是构建原生 Android 界面的新工具包。它可简化并加快 Android 上的界面开发，使用更少的代码、强大的工具和直观的 Kotlin API，快速让应用生动而精彩。")
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ){
                IconButton(onClick = { /*TODO*/ }) {
                   Icon(Icons.Filled.Favorite, contentDescription = null)
                }
                IconButton(onClick = { /*TODO*/ }) {
                   Icon(Icons.Filled.Chat, contentDescription = null)
                }
                IconButton(onClick = { /*TODO*/ }) {
                    Icon(imageVector = Icons.Filled.Share, contentDescription = null)
                }
            }
        }
    }
}
```

![img](https://jetpackcompose.cn/assets/images/demo-dce9d649a23d5dbd25812795423cb578.png)

Row 组件中的 horizontalArrangement 参数帮助我们合理地分配了按钮的水平位置，可以看到，喜欢按钮和分享按钮被分配在了左右两边，事实上，Arrangment 就是来帮助我们快速安排好子项的位置，除了 Center（居中）, Start（水平靠左）, End（水平靠右） 这些常见的位置，还有一些在特定场景下可能用到的位置分布，例如 Space Between, Space Evenly 等等。

![img](https://jetpackcompose.cn/assets/images/demo2-af7c07390ecb8ee1704ab66908b51f3f.png)

## Scaffold

```kotlin
@Composable
fun Scaffold(
    modifier: Modifier = Modifier,
    scaffoldState: ScaffoldState = rememberScaffoldState(),
    topBar: @Composable () -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    snackbarHost: @Composable (SnackbarHostState) -> Unit = { SnackbarHost(it) },
    floatingActionButton: @Composable () -> Unit = {},
    floatingActionButtonPosition: FabPosition = FabPosition.End,
    isFloatingActionButtonDocked: Boolean = false,
    drawerContent: @Composable (ColumnScope.() -> Unit)? = null,
    drawerGesturesEnabled: Boolean = true,
    drawerShape: Shape = MaterialTheme.shapes.large,
    drawerElevation: Dp = DrawerDefaults.Elevation,
    drawerBackgroundColor: Color = MaterialTheme.colors.surface,
    drawerContentColor: Color = contentColorFor(drawerBackgroundColor),
    drawerScrimColor: Color = DrawerDefaults.scrimColor,
    backgroundColor: Color = MaterialTheme.colors.background,
    contentColor: Color = contentColorFor(backgroundColor),
    content: @Composable (PaddingValues) -> Unit
)
```

`Scaffold` 实现了 **Material Design** 的基本视图界面结构

![image-20220921173526841](https://s2.loli.net/2022/09/21/OypWfVuZaMdLS2K.png)

如下代码创建了一个简单页面：

![img](https://jetpackcompose.cn/assets/images/demo-d0ad275e919542fdc357e6c396fabaa1.gif)

```kotlin
@Composable
fun AppScaffold() {

    val scaffoldState = rememberScaffoldState()
    val scope = rememberCoroutineScope()

    var selectedItem by remember { mutableStateOf(0) }
    val items = listOf("主页", "我喜欢的", "设置")

    Scaffold(
        scaffoldState = scaffoldState,
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(
                        onClick = {
                            scope.launch {
                                scaffoldState.drawerState.open()
                            }
                        }
                    ) {
                        Icon(Icons.Filled.Menu, null)
                    }
                },
                title = {
                    Text("魔卡沙的炼金工坊")
                }
            )
        },
        bottomBar = {
            BottomNavigation {
                BottomNavigation {
                    items.forEachIndexed { index, item ->
                        BottomNavigationItem(
                            icon = {
                                when(index){
                                    0 -> Icon(Icons.Filled.Home, contentDescription = null)
                                    1 -> Icon(Icons.Filled.Favorite, contentDescription = null)
                                    else -> Icon(Icons.Filled.Settings, contentDescription = null)
                                }
                            },
                            label = { Text(item) },
                            selected = selectedItem == index,
                            onClick = { selectedItem = index }
                        )
                    }
                }
            }
        },
        drawerContent = {
            AppDrawerContent(scaffoldState, scope)
        }
    ) {
        // 此处需要编写主界面

        // 这里的例子只调用了一个 AppContent
        // 要和 BottomNavigation 合理搭配，显示不同的界面的话
        // 考虑使用 Jetpack Compose Navigation 来实现会更加合理一些
        // 会在文档的后面介绍 Jetpack Compose Navigation

        // 这里的 AppContent 是个伪界面
        // 如果你要先简单的实现多界面，你可以这样编写
        /*
           when(selectedItem) {
                0 -> { Home() }
                1 -> { Favorite() }
                else -> { Settings() }
           }
         */
        // Home(), Favorite(), Settings() 都是单独的 Composable 函数

        AppContent(item = items[selectedItem])
    }
}

@Composable
fun AppContent(
    item: String
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text("当前界面是 $item")
    }
}

@OptIn(ExperimentalMaterialApi::class)
@Composable
fun AppDrawerContent(
    scaffoldState: ScaffoldState,
    scope: CoroutineScope
) {

    Box {
        Image(
            painter = painterResource(id = R.drawable.background),
            contentDescription = null
        )
        Column(
            modifier = Modifier.padding(15.dp)
        ) {
            Image(
                painter = painterResource(id = R.drawable.avatar),
                contentDescription = null,
                modifier = Modifier
                    .clip(CircleShape)
                    .size(65.dp)
                    .border(BorderStroke(1.dp, Color.Gray), CircleShape)
            )
            Spacer(Modifier.padding(vertical = 8.dp))
            Text(
                text = "游客12345",
                style = MaterialTheme.typography.body2
            )
        }
    }

    ListItem(
        icon = {
            Icon(Icons.Filled.Home, null)
        },
        modifier = Modifier
            .clickable {

            }
    ) {
        Text("首页")
    }

    Box(
        modifier = Modifier.fillMaxHeight(),
        contentAlignment= Alignment.BottomStart
    ) {
        TextButton(
            onClick = { /*TODO*/ },
            colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colors.onSurface),
        ) {
            Icon(Icons.Filled.Settings, null)
            Text("设置")
        }
    }

    // 编写逻辑
    // 如果 drawer 已经展开了，那么点击返回键收起而不是直接退出 app

    BackHandler(enabled = scaffoldState.drawerState.isOpen) {
        scope.launch {
            scaffoldState.drawerState.close()
        }
    }
}
```

## Surface

```kotlin
@Composable
fun Surface(
    modifier: Modifier = Modifier,
    shape: Shape = RectangleShape,
    color: Color = MaterialTheme.colors.surface,
    contentColor: Color = contentColorFor(color),
    border: BorderStroke? = null,
    elevation: Dp = 0.dp,
    content: () -> Unit
): @Composable Unit
```

Surface 从字面上来理解，是一个平面，在 `Material Design` 设计准则中也同样如此，我们可以将很多的组件摆放在这个平面之上，我们可以设置这个平面的边框，圆角，颜色等等。接下来，我们来用 Surface 组件做出一些不同的效果。

```kotlin
fun SurfaceTest(){
    Surface(
        shape = RoundedCornerShape(8.dp),
        elevation = 10.dp,
        modifier = Modifier
            .width(300.dp)
            .height(100.dp)
    ){
        Row(
            modifier = Modifier
                .clickable {  }
        ){
            Image(
                painter = painterResource(id = R.drawable.p_1),
                contentDescription = "This is a flower",
                modifier = Modifier.size(100.dp),
                contentScale = ContentScale.Crop
            )
            Spacer(Modifier.padding(vertical = 12.dp))

            Column(
                modifier = Modifier.fillMaxHeight(),
                verticalArrangement = Arrangement.Center
            ){
                Text(text = "Liratie",
                style = MaterialTheme.typography.h6)
                Spacer(Modifier.padding(vertical = 8.dp))
                Text(text = "花语t")
            }
        }
    }
}
```

## 自定义布局

**Compose UI 不允许多次测量**，当前UI元素的每一个子元素均不能被重复进行测量，换句话说就是**每个子元素只允许被测量一次**

### Modifier.layout

`Modifier.layout()`可以手动控制元素的测量和布局

有时你想在屏幕上展示一段文本信息，通常你会使用到 Compose 内置的 Text 组件。单单显示文本是不够的，你希望指定 Text 顶部到文本基线的高度，让文本看的更自然一些。使用内置的 padding 修饰符是无法满足你的需求的，他只能指定 Text 顶部到文本顶部的高度，此时你就需要使用到 layout 修饰符了。

![img](https://jetpackcompose.cn/assets/images/demo1-c7d546f50c0de8e88ec86ce335c2ce48.png)

```kotlin
fun Modifier.firstBaselineToTop(
  firstBaselineToTop: Dp
) = Modifier.layout { measurable, constraints ->
  ...
  val placeableY = firstBaselineToTop.roundToPx() - firstBaseline
  val height = placeable.height + placeableY
  layout(placeable.width, height) {
    placeable.placeRelative(0, placeableY)
  }
}
```

## Layout Composable

Layout Modifier 会将当前元素的所有子元素视作为整体进行统一的测量与布局，多适用于统一处理的场景。然而我们有时是需要精细化测量布局每一个子组件，这需要我们进行完全的自定义 Layout。这类似于传统 View 系统中定制 View 与 ViewGroup 测量布局流程的区别。

```kotlin
@Composable
fun MyOwnColumn(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Layout(
        modifier = modifier,
        content = content
    ) { measurables, constraints ->
        val placeables = measurables.map { measurable ->
            measurable.measure(constraints)
        }
        var yPosition = 0
        layout(constraints.maxWidth, constraints.maxHeight) {
            placeables.forEach { placeable ->
                placeable.placeRelative(x = 0, y = yPosition)
                yPosition += placeable.height
            }
        }
    }
}
```

```java
@Composable
fun BodyContent(modifier: Modifier = Modifier) {
    MyOwnColumn(modifier.padding(8.dp)) {
        Text("MyOwnColumn")
        Text("places items")
        Text("vertically.")
        Text("We've done it by hand!")
    }
}
```

预览效果：

![image-20221019201016373](https://s2.loli.net/2022/10/19/XyfkDdCQ3iO2lEb.png)

## 固有特性测量

Compose禁止了多次测量，因此，固有特性测量实现了预先获取文案组件高度信息从而确认自身的高度信息。

在 Jetpack Compose 代码实验室中就提供了这样一种场景，我们希望中间分割线高度与两边文案高的一边保持相等。

![img](https://jetpackcompose.cn/assets/images/demo1-409bfc7f18752b5e2130aefa076cfeee.png)

在上面所提到的例子中父组件所提供的能力使用基础组件中的 Row 组件即可承担，我们仅需为 Row 组件高度设置固有特性测量即可。我们使用 `Modifier.height(IntrinsicSize.Min)` 即可为高度设置固有特性测量。

### 基础组件中使用固有属性测量

```kotlin
@Composable
fun TwoTexts(modifier: Modifier = Modifier, text1: String, text2: String) {
    Row(modifier = modifier.height(IntrinsicSize.Min)) { // I'm here
        Text(
            modifier = Modifier
                .weight(1f)
                .padding(start = 4.dp)
                .wrapContentWidth(Alignment.Start),
            text = text1
        )

        Divider(color = Color.Black, modifier = Modifier.fillMaxHeight().width(1.dp))
        Text(
            modifier = Modifier
                .weight(1f)
                .padding(end = 4.dp)
                .wrapContentWidth(Alignment.End),
            text = text2
        )
    }
}

@Preview
@Composable
fun TwoTextsPreview() {
    LayoutsCodelabTheme {
        Surface {
            TwoTexts(text1 = "Hi", text2 = "there")
        }
    }
}
```

通过使用固有特性测量即可完成上面所述场景的需求，展示效果如图所示。

![img](https://jetpackcompose.cn/assets/images/demo2-53a6efde1c3c26b2808d58a711249213.png)

`minIntrinsicHeight` 与 `maxIntrinsicHeight` 有相同的两个参数 `measurables` 与 `width``measurables`：类似于 `measure` 方法的 measurables，用于获取子组件的宽高信息。`width`：父组件所能提供的最大宽度（无论此时是 `minIntrinsicHeight` 还是 `maxIntrinsicHeight` ）

### 为自定义Layout适配固有属性

对于适配固有特性测量的 Layout，我们需要对 MeasurePolicy 下的固有特性测量方法进行重写。还记得 MeasurePolicy 是谁吗？没错他就是我们在自定义 Layout 中传入的最后的 lambda SAM 转换的实例类型。

```kotlin
@Composable inline fun Layout(
    content: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    measurePolicy: MeasurePolicy
) 
```



对于固有特性测量的适配，我们需要根据需求重写以下四个方法。

![img](https://jetpackcompose.cn/assets/images/demo4-0bbf8aa03d3974f8e62e54271c3244e0.png)

使用 `Modifier.width(IntrinsicSize.Max)` ，则会调用 `maxIntrinsicWidth` 方法

使用 `Modifier.width(IntrinsicSize.Min)` ，则会调用 `minIntrinsicWidth` 方法

使用 `Modifier.height(IntrinsicSize.Max)` ，则会调用 `maxIntrinsicHeight` 方法

使用 `Modifier.height(IntrinsicSize.Min)` ，则会调用 `minIntrinsicHeight` 方法

⚠️ **注意事项：** 如果哪个 Modifier 使用了, 但其对应方法没有重写仍会崩溃。

在 Layout 声明时，我们就不能使用 SAM 形式了，而是要规规矩矩实现 MeasurePolicy

```kotlin
IntrinsicRow(
    modifier = Modifier
    	.fillMaxWidth()
    	.height(IntrinsicSize.Min)
){
    Text("left", Modifier.wrapContentWidth(Alignment.Start).layoutId("main"))
    Divider(color = Color.Black, modifier = Modifier.width(4.dp)
            .fillMaxHeight()
            .layoutId("devider"))
    Text("right", Modifier.wrapContentWidth(Alignment.End).layoutId("main")) 
}
```

此时，由于声明了 `Modifier.fillMaxWidth()`，导致我们自定义 Layout 宽度是固定的，又因为我们使用了固有特性测量，此时我们自定义 Layout 的高度也是固定的。具体表现为 constraints 参数中 minWidth 与 maxWidth 相等（宽度固定），minHeight 与 maxHeight 相等（高度固定）。

而我们希望 Devider 测量的宽度不应是固定与父组件相同，而是要根据其自身声明的宽度，也就是 `Modifier.width(4.dp)` ，所以我们对 Devider 测量使用的 constraints 进行了修改。将其最小值设置为零。

```kotlin
@Composable
fun IntrinsicRow(modifier: Modifier, content: @Composable () -> Unit){
    Layout(
        content = content,
        modifier = modifier,
        measurePolicy = object: MeasurePolicy {
            override fun MeasureScope.measure(
                measurables: List<Measurable>,
                constraints: Constraints
            ): MeasureResult {
                var devideConstraints = constraints.copy(minWidth = 0)
                var mainPlaceables = measurables.filter {
                    it.layoutId == "main"
                }.map {
                    it.measure(constraints)
                }
                var devidePlaceable = measurables.first { it.layoutId == "devider"}.measure(devideConstraints)
                var midPos = constraints.maxWidth / 2
                return layout(constraints.maxWidth, constraints.maxHeight) {
                    mainPlaceables.forEach {
                        it.placeRelative(0, 0)
                    }
                    devidePlaceable.placeRelative(midPos, 0)
                }
            }

            override fun IntrinsicMeasureScope.minIntrinsicHeight(
                measurables: List<IntrinsicMeasurable>,
                width: Int
            ): Int {
                var maxHeight = 0
                measurables.forEach {
                    maxHeight = it.maxIntrinsicHeight(width).coerceAtLeast(maxHeight)
                }
                return maxHeight
            }
        }
    )
}
```

固有特性测量的本质就是父组件可在正式测量布局前预先获取到每个子组件宽高信息后通过计算来确定自身的固定宽度或高度，从而间接影响到其中包含的部分子组件布局信息。也就是说子组件可以根据自身宽高信息从而确定父组件的宽度或高度，从而影响其他子组件布局。在我们使用的方案中，我们通过文案子组件的高度确定了父组件的固定高度，从而间接确定了分割线的高度。此时子组件要通过固有特性测量这种方式，通过父组件而对其他子组件产生影响，然而在有些场景下我们不希望父组件参与其中，而希望子组件间通过测量的先后顺序直接相互影响，Compose 为我们提供了 SubcomposeLayout 来处理这类子组件存在依赖关系的场景。

## SubcomposeLayout

SubcomposeLayout 允许子组件的合成过程延迟到父组件实际发生测量时机进行，为我们提供了更强的测量定制能力。前面我们曾提到，固有特性测量的本质是子组件通过父组件对其他子组件产生影响，利用 SubcomposeLayout，我们可以做到将某个子组件的合成过程延迟至他所依赖的组件测量结束后进行。这也说明这个组件可以根据其他组件的测量信息确定自身的尺寸，从而具备取代固有特性测量的能力。

```kotlin
@Composable
fun SubcomposeRow(
    modifier: Modifier,
    text: @Composable () -> Unit,
    divider: @Composable (Int) -> Unit
){
    SubcomposeLayout(modifier = modifier){constraints ->
        var maxHeight = 0
        val placeables = subcompose("text", text).map {
            val placeable = it.measure(constraints)
            maxHeight = placeable.height.coerceAtLeast(maxHeight)
            placeable
        }
        val dividerPlaceable = subcompose("divider"){
            divider(maxHeight)
        }.map {
            it.measure(constraints.copy(minWidth = 0))
        }
        assert(dividerPlaceable.size == 1){"DividerScope Error"}
        val midPos = constraints.maxWidth shr 1
        layout(constraints.maxWidth, constraints.maxHeight){
            placeables.forEach {
                it.placeRelative(0, 0)
            }
            dividerPlaceable.forEach{
                it.placeRelative(midPos, 0)
            }
        }
    }
}

@Composable
fun SubcomposeRowTest(){
    SubcomposeRow(modifier = Modifier.fillMaxWidth(),
        text = {
            Text(text = "left", Modifier.wrapContentWidth(Alignment.Start))
            Text(text = "right", Modifier.wrapContentWidth(Alignment.End))
        }
    ) {
        var heightPx = with(LocalDensity.current){it.toDp()}
        Divider(
            color = Color.Black,
            modifier = Modifier
                .width(4.dp)
                .height(heightPx)
        )
    }
}

```

最终效果与使用固有特性测量完全相同。

![img](data:image/png;base64,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)

SubcomposeLayout 具有更强的灵活性，然而性能上不如常规 Layout，因为子组件的合成需要要迟到父组件测量时才能进行，并且需要还需要额外创建一个子 Composition，因此 SubcomposeLayout 可能并不适用在一些对性能要求比较高的 UI 部分。

## ParentData

```kotlin
Box(modifier = Modifier
            .fillMaxSize()
            .wrapContentSize(align = Alignment.Center)
            .size(50.dp)
            .background(Color.Blue))
```

`Box` 在其 `content` 作用域中提供了 `align` 方法，这可以让**子微件自行告知父布局：我需要居中**

```kotlin
@Immutable
interface BoxScope {
    @Stable
    fun Modifier.align(alignment: Alignment): Modifier

    @Stable
    fun Modifier.matchParentSize(): Modifier
}
```

作为接口，在此作用域中，子微件就可以调用 `align` 告诉父微件自己的align方式了

### 实现一个简易版weight

```kotlin

interface VerticalScope{
    @Stable
    fun Modifier.weight(weight: Float): Modifier
}
class WeightParentData(val weight: Float = 0f): ParentDataModifier{
    override fun Density.modifyParentData(parentData: Any?) = this@WeightParentData
}
object VerticalScopeInstance: VerticalScope{
    @Stable
    override fun Modifier.weight(weight: Float): Modifier = this.then(
        WeightParentData(weight)
    )
}
@Composable
fun WeightVerticalLayout(
    modifier: Modifier = Modifier,
    content: @Composable VerticalScope.() -> Unit
){
    val measurePolicy = MeasurePolicy{ measurables, constraints ->
        val placeables = measurables.map{it.measure(constraints.copy(minWidth = 0))}
        val weights = measurables.map{(it.parentData as WeightParentData).weight}
        val totalHeight = constraints.maxHeight
        val totalWeight = weights.sum()
        val width = placeables.maxOf{it.width}
        layout(width, totalHeight){
            var y = 0
            placeables.forEachIndexed { i, placeable ->
                placeable.placeRelative(0, y)
                y += (totalHeight * weights[i] / totalWeight).toInt()
            }
        }
    }
    Layout(modifier = modifier, content = {VerticalScopeInstance.content()}, measurePolicy = measurePolicy)
}

@Preview(showSystemUi = true)
@Composable
fun PreviewWeightedVerticalLayout(){
    WeightVerticalLayout(
        Modifier.padding(16.dp).height(200.dp)
    ){
        Box(modifier = Modifier.width(40.dp).weight(1f).background(randomColor()))
        Box(modifier = Modifier.width(40.dp).weight(2f).background(randomColor()))
        Box(modifier = Modifier.width(40.dp).weight(7f).background(randomColor()))
    }
}
```

最终效果如下，可以看到，三个Box正确按照`1:2:7`的比例显示高度

![image-20220310111258869](https://web.funnysaltyfish.fun/temp_img/202203101113984.png)

# 设计

## 动画

Jetpack Compose 提供了强大的、可扩展的 API，使得在你的应用程序的用户界面上实现各种动画变得更容易。本文描述了如何使用这些 API，以及根据你的动画场景使用哪个 API。

![img](https://jetpackcompose.cn/assets/images/demo-12d411e90b1eace533239c0fff64690a.png)

| API                                                          | 功能                         |
| ------------------------------------------------------------ | ---------------------------- |
| **[AnimationVisibility](https://jetpackcompose.cn/docs/design/animation/animationvisibility)** | **显示/隐藏的过渡动画**      |
| **Modifier.contentSize**                                     | **内容大小的变化过渡动画**   |
| **Crossfade**                                                | **在两个布局之间的过渡动画** |
| **[updateTransition](https://jetpackcompose.cn/docs/design/animation/updateTransition)** | **实现过渡动画的关键 API**   |
| **[animateAsState](https://jetpackcompose.cn/docs/design/animation/animateAsState)** | **指定类型的数据变化动画**   |

### 高级动画

#### AnimatedVisibiliy

```kotlin
@Composable
fun AnimatedVisibilityTest(){
    var state by remember {
        mutableStateOf(true)
    }
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        AnimatedVisibility(visible = state) {
            Text(
                text = "This is a normal text",
                fontWeight = FontWeight.W900,
                style = MaterialTheme.typography.h5
            )
        }
        Spacer(Modifier.padding(vertical = 50.dp))
        Button(onClick = {state = !state}){
            Text(if(state) "Hidden" else "Show")
        }
    }
}
```

![img](https://jetpackcompose.cn/assets/images/demo11-1a135639156dd003120e566002947c4c.gif)

默认情况下内容通过 `fadeIn()` 和 `expandVertically()` 出现, 通过`fadeOut()`和`shrinkVertically()`消失。

可以通过指定`EnterTransition`和`ExitTransition`来自定义过渡动画

```kotlin
var state by remember{ mutableStateOf(true) }

Column(
    modifier = Modifier
        .fillMaxSize(),
    horizontalAlignment = Alignment.CenterHorizontally,
    verticalArrangement = Arrangement.Center
){
    AnimatedVisibility(
        visible = state,
        enter = slideInVertically(
            initialOffsetY = { -40 }
        ) + expandVertically(
            expandFrom = Alignment.Top
        ) + fadeIn(initialAlpha = 0.3f),
        exit = shrinkHorizontally() + fadeOut()
    ) {
        Text(
            text = "这是一个普通的正文",
            fontWeight = FontWeight.W900,
            style = MaterialTheme.typography.h5
        )
    }
    Spacer(Modifier.padding(vertical = 50.dp))
    Button(onClick = { state = !state }) {
        Text(if (state) "隐藏" else "显示")
    }
}
```

![img](https://jetpackcompose.cn/assets/images/demo10-bcfc91c79b09a6054d6dca3d7dd38d3c.gif)

`EnterTransition` 的一些方法

[`fadeIn`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#fadeIn(kotlin.Float,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-fadein.gif)

[`slideIn`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#slideIn(kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-slidein.gif)

[`expandIn`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#expandIn(androidx.compose.ui.Alignment,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-expandin.gif)

[`expandHorizontally`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#expandHorizontally(androidx.compose.ui.Alignment.Horizontal,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-expandhorizontally.gif)

[`expandVertically`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#expandVertically(androidx.compose.ui.Alignment.Vertical,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-expandvertically.gif)

[`slideInHorizontally`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#slideInHorizontally(kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-slideinhorizontally.gif)

[`slideInVertically`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#slideInVertically(kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-slideinvertically.gif)

`ExitTransition` 的一些方法

[`fadeOut`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#fadeOut(kotlin.Float,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-fadeout.gif)

[`slideOut`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#slideOut(kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-slideout.gif)

[`shrinkOut`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#shrinkOut(androidx.compose.ui.Alignment,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-shrinkout.gif)

[`shrinkHorizontally`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#shrinkHorizontally(androidx.compose.ui.Alignment.Horizontal,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-shrinkhorizontally.gif)

[`shrinkVertically`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#shrinkVertically(androidx.compose.ui.Alignment.Vertical,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-shrinkvertically.gif)

[`slideOutHorizontally`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#shrinkHorizontally(androidx.compose.ui.Alignment.Horizontal,kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec,kotlin.Boolean))

![img](https://developer.android.com/images/jetpack/compose/animation-slideouthorizontally.gif)

[`slideOutVertically`](https://developer.android.com/reference/kotlin/androidx/compose/animation/package-summary#slideOutVertically(kotlin.Function1,androidx.compose.animation.core.FiniteAnimationSpec))

![img](https://developer.android.com/images/jetpack/compose/animation-slideoutvertically.gif)

#### AnimateContentSize

```kotlin
var text by remember{mutableStateOf("animateContentSize Animation")}
Box(
	modifier = Modifier.fillMaxSize(),
    contentAlignment = Alignment.Center
){
    Text(text, modifier = Modifier
        .clickable{
            text += text;
        }.animateContentSize())
}
```

![img](https://jetpackcompose.cn/assets/images/demo-28e07a821bd06d02f1c9700ed0215d7f.gif)
