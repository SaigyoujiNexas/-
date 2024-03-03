# 简单值动画

```kotlin
val color by animateColorAsState(if(...) Colors.Purle else Colors.Green)
```

各种animate(Int/Float....)AsState方法

# 可见性动画

```kotlin
AnimatedVisbility( Boolean ){
 //Some view in There   
}
```

从顶部滑入/滑出

```kotlin
AnimatedVisbility( visible = Boolean,
                 enter = slideInVertically(
                     initialOffsetY = {fullHeight -> -fullHeight},
                     //减速缓和
                     animationSpec = (tween(durationMillis = 150, easing = LinearOutSlowInEasing)),
                     exit = slideOutVertically(
                         targetOffsetY = {
                           fullHeight -> -fullHeight
                         },
                         //加速退出
                         animationSpec = tween(durationMillis = 250, easing = FastOutLinearInEasing)
                     )
                 )
                 ){
 //Some view in There   
}
```

# 内容大小动画

```kotlin
modifier = Modifier.animateContentSize()
```



# 多值动画

 ```kotlin
 
 val transition = updateTransition(
     tabPage,
     label = "Tab indicator"
 )
 val indicatorLeft by transition.animateDp(
     label = "Indicator left"
 ){
     tabPage -> tabPostions[tabPage.ordinal].left
 }
 val color by transition.animateColor(
     label = "Border color"
 ){
     tabPage -> 
     uf(tabPage == TabPage.Home) Colors.Purple else Colors.Green
 }
 
 ```

弹性效果

```kotlin

val transition = updateTransition(
    tabPage,
    label = "Tab indicator"
)
val indicatorLeft by transition.animateDp(
    label = "Indicator left"
    transitionSpec = {
        if(TabPage.Home isTransitionTo TabPage.Work){
            spring(stiffness = Spring.StiffnessVeryLow) 
        }else{
            spring(stiffness = Spring.StiffnessMedium)
        }
    }
){
    tabPage -> tabPostions[tabPage.ordinal].left
}
val color by transition.animateColor(
    label = "Border color"
){
    tabPage -> 
    uf(tabPage == TabPage.Home) Colors.Purple else Colors.Green
}

```

# 重复动画

```kotlin
val infiniteTransition = rememberInfiniteTransition()
val alpha = infiniteTransition.animateFloat(
    
    initialValue = 0f,
    targetValue = 1f,
    animationSpec = infiniteRepeatable(
        animation = keyframes{
            durationMillis = 1000
            1f at 500
        },
        repeatMode = RepeatMode.Reverse
        // 0 to 1, 1 to 0 to 1 to 0....
    )
)
```

# 手势动画

//滑动删除

![image-20220317211430758](https://s2.loli.net/2022/03/17/fcbByWGDUIt9x8i.png)

```kotlin
//1. 元素跟随手指滑动
//2. 根据惯性决定是否删除， 计算最终元素被抛掷的坐标位置

```

```kotlin
private fun Modifier.swipeToDismiss(
    onDismissed: () -> Unit
) : Modifier = composed{
    val offsetX = remember{Animatable(0f)}
    val velocityTracker = VelocityTracker()
    //创建一个修饰符， 用于处理修改元素区域内的光标输入
    //pointerInputs可以调用PointerinputScope.awaitPointerEventScope.
    //以安装可以等待PointerEventScope的光标输入程序
    pointerInput(Unit){
        
        val decay = splineBasedDecay<Float>(this)
        
        coroutineScope{
        while(true){
            //awaitPointerEventScope: 挂起并安装指针输入块
           val pointerId =  awaitPointerEventScope{awaitFirstDown().id}
            awaitPointerEventScope{
                horizontalDrag(pointerId){
                    change -> 
                    val horizontalDragOffset = offsestX.value + change.positionChange().x
                 launch{
                    offsetX.snapTo(horizontalDragOffset)
                }}
                velocityTracker.addPosition(change.uptimeMills, change.position)
                change.consumePositionChnage()
            }
        }
            val velocity = velocityTracker.calculateVelocity().x
            //计算抛掷最终位置
            val targetOffsetX = decay.calculateTragetValue(offsetX.value, velocity)
            offsetX.updateBounds(
                lowerBound = -size.width.toFloat(),
                upperBound = size.width.toFloat()
            )
            launch{
                if(targetOffsetX.absoluteValue <= size.width){
                    offsetX.animateTo(targetValue = 0f, initialVelocity = velocity)
                }
                else{
                    offsetX.animateDecay(velocity, decay)
                    onDismissed()
                }
            }
        }
    }.offset{
        IntOffset(offsetX.value.roundToInt(), 0)
    }
}
```

# 手势

1. 点击
2. 滚动
3. 拖动
4. 滑动
5. 多点触控

## 点击

clickable修饰符允许点击

当需要更大灵活性， 使用pointerInout

```kotlin
fun GestureSample(){
    Row(
    verticalAlignment = Alignment.ConterVertically,
        
    ){
        ClickableSample()
    }
}

@Composable
fun ClickableSample(){
    val count = remember{
        mutableStateOf(0)
    }
    Text{
        text = count.value.toString(),
        textAlign = TextAlign.Center,
        modifier = Modifier.clickable{
            count.value++;
        }
        //use pointerInput
        。pointerInpput(Uint){
            detectTapGestures(
                onPress = {},
                onDoubleTap = {},
                onLongPress = {},
                onTap = ()
            )
        }
        .wrapContentSize().
       	background(Color.LightGray)
        .padding(horizontal = 50.dp, vertical = 50.dp)
    }
}

```

## 滚动修饰符

```kotlin
@Composable
fun ScrollBoxes(){
    val state = rememberScrollState()
    LaunchedEffect(Unit){
        state.animateScrollTo(100)
    }
    Column(
        modifier = Midifier.background(Color.LightGray)
        .size(100.dp)
        .verticalScroll(state)
    ){
        repeat(10){
            Text("Item$it", modifier = Modifier.padding(2.dp))
        }
        
    }
}
```

## 可滚动的修饰符

```kotlin
@Composable()
fun ScrollableSmple(){
    
    var offset by remember {mutableStateOf(0f)}
    Box(Modifier.size(150.dp)
        .scrollable(
        orientation = Orientation.Vertical,
            state = rememberScrollableState{delta -> offset += delta
                                           delta}
        )
        .background(Color.LightGray),
        contentAlignment = Alignment.Center
       ){
        Text(text = offset.toString())
    }
}
```

## 自动嵌套滚动

compose自动完成了嵌套滚动

```kotlin
@Composable
fun NestedScrollSample(){
    val gradient = Brush.verticalGradient(
        0f to Color.LightGray,1000f to Color.White
    )
    Box(
        Modifier = Modifier
        .background(Color.LightGray)
        .verticalScroll(rememberScrollState())
        .padding(32.dp)
        {
            Column{
                repeat(6){
                    Box(
                    modifier = Modifier.height(126.dp)
                    .vertiacalScroll(rememberScrollState())){
                        Text(
                       text = "Scroll here",
                        modifier = Modifier.
                            wrapContentSize()
                            .background(gradient)
                        )
                    }
                }
            }            }
        }
    )
}
```

## 拖动

```kotlin
@Composable
fun DraggleableSample(){
    var offsetX by remember{mutableStateOf(0f)}
    
    Text(text = "Drag me!",
         modifier = Modifier
         .offset{IntOffset(offsetX.roundToInt(), 0)}
         .draggable(
         	orientation - Orientation.Horizontal,
             state = rememverDraggableState{
                 delta -> offsetX += delta
             }
         )
        )
}
// more complex drag shoule use pointerInput
@Composable
fun DragWhereYouWantSample(){
    
    Box(
    ){
        var offsetX by remember{mutableStateOf(0f)}
    var offsetY by remember{mutableStateOf(0f)}
        Box(MOdifier.offset{IntOffset(offsetX.roundToInt(), offsetY.roundToInt())})
        .background(Color.Blue)
        .size(50.dp)
        .pointerInput(Unit){
            detectDragGestures{
                change, dragAmount ->
                offsetX += change.x
                offsetY += change.y
            }
        }
    }
}
```

## 滑动

使用swipeable 修饰符，通常呈现方式为滑动删除， 滑动关闭

```kotlin
@Composable
fun SwipeableSample(){
    val width = 96.dp
    val squareSize = 48.dp
    val state = rememberSwipeableState(0)
    val sizePx = with(LocalDensity.current){
        squareSize.toPx()
    }
    
    val anchors = mapOf(0f, to 0,sizePx to 1)
    Box(
    modifier = Modifer.width(width)
        .swipeable(
            state = state,
            anchors = anchors,
            tresholds = {_, _ -> FractionalThreshold(0.3f)},
            orientation = Orientation.Horizontal
        )
    ){
        Box(
            modifer = Modifier
            .offset{IntOffset(if(state == 0) 0.dp else 48.dp, 0)}
            .size(squareSize)
            .background(Color.DarkGray)
        )
    }
}
```

## 多点触控： 平移，缩放， 旋转

```kotlin
@Composable
fin TransformableSample(){
    val scale by remeber{mutableStateOf(1f)}
    val rotate by remeber{mutableStateOf(0f)}
    val offset by remeber{mutableStateOf(Offset.Zero)}
    val state = rememberTransformableState{
        zoomChange, panChange, rotationChange ->
        
    }
    Box(
    Modifier.graphicsLayer(
        scaleX = scale,
        scaleY = scale, 
        rotation = .....
    ).transformable(state))
}
```

