View是Android中所有控件的基类

# View的基本信息

## View 的位置参数

View由四个顶点决定， top, left, right, bottom.

```java
var width = right - left;
var height = bottom - top;
```

Android3.0添加的参数：

* x: 左上角x位置
* y: 左上角y位置
* translationX:左上角X偏移量
* translationY：左上角y偏移量

## MotionEvent 和 TouchSlop

### MotionEvent

* ACTION_DOWN 手指刚接触屏幕
* ACTION_MOVE 手指在屏幕上移动
* ACTION_UP   手指从屏幕上松开一瞬间

### TouchSlop

TouchSlop是系统所能识别被认为是滑动的最小距离。

通过

```java
ViewConfiguration.get(context).getScaledTouchSlop()
```

## VelocityTracker, GestureDetector 和 Scroller

### VelocityTracker

用于计算速度

```java
VelocityTracker velocityTracker = VelocityTracker.obtain();
velocityTracker.addMovement(event);
//获取速度
velocityTracker.computeCurrentVelocity(1000);
int xVelocity = (int) velocityTracker.getXVelocity();
int yVelocity = (int) velocityTracker.getYVelocity();
//回收
velocityTracker.clear();
volocityTracker.recycle();
```

`v = (Pend - Pstart) / time`

### GestureDetector

用于辅助检测用户的单击，滑动，长按，双击。

假设要实现双击功能:

```java
GestureDetector gestureDetector = new GestureDetector(this);
//解决长按后无法拖动。
gestureDetector.setIsLongpressEnabled(false);
//接管onTouchEvent方法
Boolean consume = gestureDetector.onTouchEvent(event);
return consume;
```

onGestureListener和onDoubleTapListener中的方法

|        方法名        |                             描述                             |      所属接口       |
| :------------------: | :----------------------------------------------------------: | :-----------------: |
|        onDown        |                   由一个 ACTION_DOWN 触发                    |  onGestureListener  |
|     onShowPress      |          由一个ACTION_DOWN触发，但是尚未松开或拖动           |  onGestureListener  |
|    onSingleTapUp     |             轻触屏幕后松开,伴随一个ACTION_UP触发             |  OnGestureListener  |
|       onScroll       |  按下屏幕并拖动，由一个ACTION_DOWN 和 多个 ACTION_MOVE 触发  |  OnGestureListener  |
|     onLongPress      |                 用户长久按住屏幕不方，即长按                 |  OnGestureListener  |
|       onFling        | 按下触摸屏，快速滑动后松开，由一个ACTION_DOWN，多个ACTION_MOVE, 一个ACTION_UP触发 |  OnGestureListener  |
|     onDoubleTap      |  双击，由两次连续的单击组成，无法和onSingleTapConfirmed共存  | OnDoubleTapListener |
| onSingleTapConfirmed |        严格的单机行为，不可能会是双击中的一个单击行为        | OnDoubleTapListener |
|   onDoubleTapEvent   |               发生了双击行为，在双击的期间发生               | OnDoubleTapListener |

 ### Scroller

用于实现View的弹性滑动。

```java
Scroller scroller = new Scroller(mContext);
private void smoothScrollTo(int x, int y){
    int scrollX = getScrollX();
    int delta = destX - scrollX;
    scroller.startScroll(scrollX, 0, delta, 0, 1000);
    invalidate();
}
@Override
public void computeScroll(){
    if(scroller.computeScrollOffset()){
        scrollTo(scroller.getCurrX(), scroller.getCurrY());
        postInvalidate();
    }
}
```

# View 的滑动

可以通过三种方式实现View的滑动:

* View本身的 scrollTo / scrollBy 方法
* 通过动画给View施加平移效果
* 通过改变View的LayoutParams是View重新布局

## 使用scrollTo/scrollBy

```java
public void scrollTo(int x, int y){
    if(mScrollX != x || mScrollY != y){
        int oldX = mScrollX;
        int oldY = mScrollY;
        mScrollX = x;
        mScrollY = y;
        invalidateParentCaches();
        onScrollChanged(mScrollX, mScrollY, oldX, oldY);
        if(!awakenScrollBars()){
            postInvalidateOnAnimation();
        }
    }
}
public void scrollBy(int x, int y){
    scrollTo(mScrollX + x, mScrollY + y);
}
```

## 使用动画

通过动画能够让一个 View实现View的平移来实现滑动。

```java
ObjectAnimator.ofFloat(targetView, "translationX", 0, 100).setDuration(100).start();
```

## 改变布局参数

```java
MarginLayourParams = (NarginLayoutParams)mButton1.getLayoutParams();
params.width += 100;
params.leftMargin += 100;
mButton1.requestLayout();
```

实现一个跟手滑动效果

```kotlin
    override fun onTouchEvent(event: MotionEvent): Boolean {
        val x = event.rawX
        val y = event.rawY
        when(event.action){
            MotionEvent.ACTION_MOVE -> {
                val deltaX = x - mLastX
                val deltaY = y - mLastY
                ObjectAnimator
                    .ofFloat(this, "translationX", translationX, translationX + deltaX)
                    .setDuration(0).start()
                ObjectAnimator
                    .ofFloat(this, "translationY", translationY, translationY + deltaY)
                    .setDuration(0).start()
            }
            else -> {
            }
        }
        mLastX = x.toInt()
        mLastY = y.toInt()
        return true
    }
```

# 弹性滑动

## 使用Scroller

Scroller的使用

```java
Scroller scroller = new Scroller();

private smoothScrollTo(int destX, int destY){
    int scrollX = getScrollX();
    int deltaX = destX - scrollX;
    mScroller.startScroll(scrollX, 0, deltaX, 0, 1000);
    invalidate();
}
@Override
public void computeScroll(){
    if(mScroller.computeScrollOffset()){
        scrollTo(mScroller.getCurrX(), mScroller.getCurrY());
        postInvalidate();
    }
}
```

```java
public void startScroll(int startX, int startY, int dx, int dy, int duration){
    mMode = false;
    mDuration = duration;
    mStartTime = AnimationUtils.currentAnimationTimeMillis();
    mStartX = startX;
    mStartY = startY;
    mFinalX = startX + dx;
    mFinalY = startY + dy;
    mDeltaX = dx;
    mDeltaY = dy;
    mDurationReciprocal = 1.0f / (float) mDuration;
}
```

Scroller 中的`computeScrollOffset`方法的实现。

这里就是计算了一个`s(n) = s(0) + Δs * Δt` 

```java
public boolean computeScrollOffset(){
    //...
    int timePassed = (int) (AnimationUtils.currentAnimationTimeMillis() - mStartTime);
    if(timePassed < mDuration){
        switch(mMode){
                case(SCROLL_MODE):
                	final float x = mInterpolator.getInterpolation(timePasswd * mDurationReciprocal);
                mCurrX = mStartX + Math.round(x * mDeltaX);
                mCurrY = mStartY + Math.round(x * mDeltaY);
                break;
        }
    }
    return true;
}
```

## 通过动画

```java
ObjectAnimator.ofFloat(targetView, "translationX", 0, 100).setDuration(100).start();
```

动画实现就很是方便。

同时可以使用动画实现一些动画不能实现的效果

```java
final int startX = 0;
final int deltaX = 100;
ValueAnimator animator
```





