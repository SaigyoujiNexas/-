这还是第一次去看这种Android的框架，算了看到哪儿算哪儿吧。

# 布局的指挥员--`LayoutManager`

## 与`RecyclerView`的互绑定

```java
//RecyclerView.LayoutManager.setRecyclerView
void setRecyclerView(RecyclerView recyclerView){
    if(recyclerView == null){
        mRecyclerView = null;
        mChildHelper = null;
        mWidth = 0;
        mHeight = 0;
    }else{
        mRecyclerView = recyclerView;
        mChildHelper = recyclerView.mChildHelper;
        mWidth = recyclerView.getWidth();
        mHeight = recyclerView.getHeight();
    }
    mWidthMode = MeasureSpec.EXACTLY;
    mHeightMode = MeasureSpec.EXACTLY;
}
```

```java
//RecyclerView.setLayoutManager
public void setLayoutManager(LayoutManager layout){
    if(layout == mLayout){
        return;
    }
    stopScroll();
    if(mLayout != null){
        if(mItemAnimator != null){
            mItemAnimator.endAnimations();
        }
        mLayout.removeAndRecycleAllViews(mRecycler);
        mLayout.removeAndRecycleScrapInt(mRecycler);
        mRecycler.clear();
        
        if(mIsAttached){
            mLayout.dispatchDetachedFromWindow(this, mRecycler);
        }
        mLayout.setRecyclerView(null);
        mLayout = null;
    }else{
        mRecycler.clear();
    }
    //this is just a defensive measure for faulty item animators.
    mChildHelper.removeAllViewsUnfiltered();
    mLayout = layout;
    if(layout != null){
        if(layout.mRecyclerView != null){
            throw new IllegalArmentException("LayoutManager" + layout
                                            + "is already attached to a RecyclerView:" + layout.mRecyclerView.exceptionLabel());
        }
        mLayout.setRecyclerView(this);
        if(mIsAttached){
            mLayout.dispatchAttachedToWindow(this);
        }
    }
    mRecycler.updateViewCacheSize();
    requestLayout();
}
```

当完成`setLayoutManager`后，整个布局会清空并重新绑定刷新。并通过`requestLayout`调用`Layout`方法

## 布局管理

```java
//RecyclerView.onLayout
protected void onLayout(boolean changed, int l, int t, int r, int b){
    TraceCompat.beginSection(TRACE_ON_LAYOUT_TAG);
    dispatchLayout();
    TraceCompat.endSection();
    mFirstLayoutComplete = true;
}
```

这里可以看到，在`RecyclerView`的`onLayout`中使用了`dispatchLayout`将布局委托出去，随后将`mFirstLayoutComplete`的值设置为true

```java
//RecyclerView.dispatchLayout
void dispatchLayout(){
    if(mAdapter == null){
        Log.e(...);
        return;
    }
    if(mLayout == null){
        Log.e(...);
        return;
    }
    mState.mIsMeasuring = false;
    if(mState.mLayoutStep == State.STEP_START){
        dispatchLayoutStep1();
        mLayout.setExactMeasureSpecsFrom(this);
        dispatchLayoutStep2();
    }else if(mAdapterHelper.hasUpdates() || mLayout.getWidth() != getWidth()
             || mLqayout.getHeight() != getHeight()){
        //size被改变，需要重新布局
        mLayout.setExactMeasureSpecsFrom(this);
        dispatchLayoutStep2();
    }else{
        //确保mLayout的measuseSpec始终保持同步
        mLayout.setExactMeasureSpecs(this);
    }
}
```

源代码将`Layout`分成了三步

* `dispatchStep1`： 进行预布局，记录数据更新时需要进行的动画所需的信息
* `dispatchStep2`: 由`LayoutManager`执行子View的测量，布局。
* `dispatchStep3`: 实际执行动画

### 第一步： 预布局

```java
//RecyclerView.dispatchLayoutStep1
private void dispatchLayoutStep1(){
    mState.assertLayStep(State.STEP_START);
    fillRemainingScrollValues(mState);
    mState.mIsMeasuring = false;
    startInterceptRequestLayout();
    mViewInfoStore.clear();
    onEnterLayoutOrScroll();
    processAdapterUpdatesAndSetAnimationFlags();
    saveFocusInfo();
    mState.mTrackOldChangeHolders = mState.mRunSimpleAnimations && mItemsChanged;
    mItemsAddedOrRemoved = mmItemsChanged = false;
    mState.mInPreLayout = mState.mRunPredictiveAnimations;
    mState.mItemCount = mAdapter.getItemCount();
    findMinMaxChildLayoutPositions(mMinMaxLayoutPositions);
    if(mState.mRunSimpleAnimations){
        int count = mChildHelper.getChildCount();
        for(int i = 0; i < count; i++){
            final ViewHolder holder = getChildViewHolderInt(mChildHelper.getChildAt(i));
            if(holder.shouldIgnore() || holder.isInvalid() && !mAdapter.hasStableIds()){
                continue;
            }
            final ItemHolderInfo animationInfo = mItemAnimator
                .recordPreLayoutInformation(mState, holder,
                 	ItemAnimator.buildAdapterChangeFlagsForAnimations(holder),
                    holder.getUnmodifiedPayloads());
            mViewInfoStore.addToPreLayout(holder, animationInfo);
            if(mState.mTrackOldChangeHolders && holder.isUpdated() && !holder.isRemoved() && !holder.shouIgnore() && !holder.isInvalid()){
                long key = getChangedHolderKey(holder);
                mViewInfoStore.addToOldChangeHolders(key,holder);
            }
        }
    }
    if(mState.mRunPredictiveAnimations){
        saveOldPosition();
        final boolen didStructureChange = mState.mStructureChanged;
        mState.mStructureChanged = false;
        mLayout.onLayoutChildren(mRecycler, mState);
        mState.mStructureChanged = didStructureChange;
        for(int i = 0; i < mChildHelper.getChildCount(); ++i){
            final View child = mChildHelper.getChildAt(i);
            final ViewHolder viewHolder = getChildViewHolderInt(child);
            if(viewHolder.shouldIgnore()){
                continue;
            }
            if(!mViewInfoStore.isInPreLayout(viewHolder)){
                int flags = ItemAnimator.buildAdapterChangeFlagsForAnimations(viewHolder);
                boolean wasHidden = viewHolder
                    .hasAnyOfTheFlags(ViewHolder.FLAG_BOUNCED_FROM_HIDDEN_LIST);
                if(!wasHidden){
                    flags |= ItemAnimator.FLAG_APPEARED_IN_PRE_LAYOUT;
                }
                final ItemHolderInfo animationInfo = mItemAnimator.recordPreLayoutInformation(
                mState, viewHolder, flags, viewHolder.getUnmodifiedPayloads());
                if(wasHidden){
                    recordAnimationInfoIfBouncedHiddenView(viewHolder, animationInfo);
                }else{
                    mViewInfoStore.addToAppearedInPreLayoutHolders(viewHolder, animationInfo);
                }
            }
        }
        clearOldPositions();
    }else{
        clearOldPositions();
    }
    onExitLayoutOrScroll();
    stopInterceptRequestLayout(false);
    mState.mLayoutStep = State.STEP_Layout;    
}
```

### 第二步： 实际布局

```java
private void dispatchLayoutStep2(){
    startInterceptRequestLayout();
    onEnterLayoutOrScroll();
    mState.assertLayoutStep(State.STEP_LAYOUT | State.STEP_ANIMATIONS);
    mAdapterHelper.consumeUpdatesInOnePass();
    mState.mItemCount = mAdapter.getItemCount();
    mState.mDeletedInvisibleItemCountSincePreviousLayout = 0;
    
    //运行layout
    mState.mInPreLayout = false;
    mLayout.onLayoutChildren(mRecycler, mState);
    
    mState.mStructureChanged = false;
    mPendingSavedState = null;
    //再检查item animation
    mState.mRunSimpleAnimations = mState.mRunSimpleAnimations && mItemAnimator != null;
    mState.mLayoutStep = State.STPE_ANIMATIONS;
    onExitLayoutOrScroll();
    stpeInterceptRequestLayout(false);
    
}
```

这里最核心的部分就是`mLayout.onLayoutChildren`

### 第三步：执行动画

```java
private void dispathLayoutStep3(){
    mState.assertLayoutStep(State.STEP_ANIMATIONS);
    startInterceptRequestLayout();
    onEnterLayoutOrScroll();
    mState.mLayoutStep = State.STEP_START;
    if(mState.mRunSimpleAnimations){
        //运行动画
        for(int i = mChildHelper.getChildCount() - 1; i >= 0; i--){
            ViewHolder holder = getChildViewHolderInt(mChildHelper.getChildAt(i));
            if(holder.shouldIgnore()){
                continue;
            }
            long key = getChangedHolderKey(holder);
            final ItemHolderInfo animationInfo = mItemAnimator
                .recordPostLayoutInformation(mState, holder);
            ViewHolder oldChangeViewHolder = mViewInfoStore.getFromOldChangeHolders(key);
            if(oldChangeViewHolder != null && !oldChangeViewHolder.shouldIgnore()){
                final boolean oldDisappearing = mViewInfoStore.isDisappearing(oldChangeViewHolder);
                final boolean newDisappearing = mViewInfoStore.isDisappearing(holder);
                if(oldDisappearing && oldChangeViewHolder == holder){
                    mViewInfoStore.addToPostLayout(holder, animationInfo);
                }else{
                    final ItemHolderInfo preInfo = mViewInfoStore.popFromPreLayout(oldChangeViewHolder);
                 //   添加或删除
                    mViewInfoStore.addToPostLayout(holder, animationInfo);
                    ItemHolderInfo postInfo = mViewInfoStore.popFromPostLayout(holder);
                    if(preInfo == null){
                        handleMissingPreInfoForChangeError(key, holder, oldChangeViewHolder);
                    }else{
                        animateChange(oldChangeViewHolder, holder, preInfo, postInfo, oldDisappearing, newDisappearing);
                    }
                }
            }else{
                mViewInfoStore.addToPostLayout(holder, animationInfo);
            }
        }
        // 加载view info list, 并触发动画
        mViewInfoStore.process(mViewOnfoProcessCallback);
    }
    mLayout.removeAndRecycleScrapInt(mRecycler);
    mState.mPreviousLayoutItemCount = mState.mItemCount;
    mDataSetHasChangedAfterLayout = false;
    mDispatchItemsChangedEvent = false;
    mState.mRunSimpleAnimations = false;
    
    mState.mRunPredictiveAnimations = false;
    mLayout.mRequestedSimpleAnimations = false;
    if(mRecycler.mChangedScrap != null){
        mRecycler.mChangedScrap.clear();
    }
    if(mLayout.mPrefetchMaxObservedInInitialPrefetch){
        mLayout.mPrefetchMaxCountObserved = 0;
        mLayout.mPefetchMaxObservedInInitialPrefetch = false;
        mRecycler.updateViewCacheSize();
    }
    mLayout.onLayoutCompleted(mState);
    onExitLayoutOrScroll();
    stopInterceptRequestLayout(false);
    mViewInfoStore.clear();
    if(didChildRangeChange(mMixMaxLayoutPositions[0], mMinMaxLayoutPositions[i])){
        dispatchOnScrolled(0, 0);
    }
    recoverFocusFromState();
    resetFocusInfo();

}
```





## 点击事件拦截

```java
public boolean onInterceptTouchEvent(MotionEvent e){
    if(mLayoutSuppressed){
        //当前的RecyelerView的点击事件被抑制
        return false;
    }
    //清空用户自定义的OnInterceptTouchListener.
    mInterceptingOnItemTouchListener = null;
    //从mOnItemTouchListeners中查找可以拦截的listener
    if(findInterceptingOnItemTouchListener(e)){
        cancelScroll();
        return true;
    }
    if(mLayout == null){
        return false;
    }
    final boolean canScrollHorizontally = mLayout.canScrollHorizontally();
    final boolean canScrollVertically = mLayout.canScrollVertically();
    if(mVelocityTracker == null){
        mVelocityTracker = VelocityTracker.obtain();
    }
    mVelocityTracker.addMovement(e);
    
    final int action = e.getActionMasked();
    final int actionIndex = e.getActionIndex();
    
    switch(action){
        case MotionEvent.ACTION_DOWN:
            if(mIgnoreMotionEventTillDown){
                mIgnoreMotionEventTillDown = false;
            }
            mScrollPointerId = e.getPointerId(0);
            mInitialTouchX = mLastTouchX = (int)(e.getX() + 0.5f);
            mInitialTouchY = mLastTouchY = (int)(e.getY() + 0.5f);
            
            if(mScrollState == SCROLL_STATE_SETTLING){
                getParent().requestDisallowInterceptTouchEvent(true);
                setScrollState(SCROLL_STATE_DRAGGING);
                stopNestedScroll(TYPE_NOW_TOUCH);
            }
            //clear the nested offsets.
            mNestedOffsets[0] = mNestedOffset[1] = 0;
            int nestedScrollAxis = ViewCompat.SCROLL_AXIS_NONE;
            if(canScrollHorizontally){
                nestedScrollAxis |= ViewCompat.SCROLL_AXIS_HORIZONTAL;
            }
            if(canScrollVertically){
                nestedScrollAxis |= ViewCompat.SCROLL_AXIS_VERTICALl;
            }
            startNestedScroll(nestedScrollAxis, TYPE_TOUCH);
            break;
        
        case MotionEvent.Action_POINTER_DOWN:
            mScrollPointerId = e.getPointerId(actionIndex);
            mInitialTouchX = mLastTouchX = (int) (e.getX(actionIndex) + 0.5f);
            mInitialTouchY = mLastTouchY = (int)(e.getY(actionIndex) + 0.5f);
            break;
        case MotionEvent.ACTION_MOVE:{
            final int index = e.findPointerIndex(mScrollPointerId);
            if(index < 0){
                Log.e(TAG, "Error processing scroll, pointer index for id " + mScrollPointerId + " not found. Did any MotionEvents get skipped?");
            	return false;
            }
            final int x = (int)(e.getX(index) + 0.5f);
            final int y = (int)(e.getY(index) + 0.5f);
            if(mScrollState != SCROLL_STATE_DRAGGING){
                final int dx = x - mInitialTouchX;
                final int dy = y - mInitialTouchY;
                boolean startScroll = false;
                if(canScrollHorizontally && Math.abs(dx) > mTouchSlop){
                    mLastTouchX = x;
                    startScroll = true;
                }
                if(canScrollVertically && Math.abs(dy) > mTouchSlop){
                    mLastTouchY = y;
                    startScroll = true;
                }
                if(startScroll){
                    setScrollState(SCROLL_STATE_DRAGGING);
                }
            }
        }break;
        case MotionEvent.ACTION_POINTER_UP:{
            onPointerUp(e);
        }break;
        case MotionEvent.ACTION_UP:{
            mVelocityTracker.clear();
            stopNestedScroll(TYPE_TOUCH);
        }break;
        case MotionEvent.ACTION_CANCEL:{
            cancelScroll();
        }
    }
    return mScrollState == SCROLL_STATE_DRAGGING;
}
```

这里面看起来,mScrollState是作为一个状态机进行了一个轮转。

```java
//RecyclerView mScrollState相关
private int mScrollState = SCROLL_STATE_IDLE;

void setScrollState(int state){
    if(state == mScrollState){
        return;
    }
    if(DEBUG){
        Log.d(TAG, "setting scroll state to " + state + "from" + mScrollState, new Exception());
    }
    mScrollState = state;
    if(state != SCROLL_STATE_SETTING){
        stopScrollersInternal();
    }
    dispatchOnScrollStateChanged(state);
}
void dispatchOnScrollStateChanged(int state){
    if(mLayout != null){
        mLayout.onScrollStateChanged(state);
    }
    onScrollStateChanged(state);
    
    if(mScrollListener != null){
        mScrollListener.onScrollStateChanged(this, state);
    }
    if(mScrollListeners != null){
        for(int i = mScrollListeners.size() - 1, i >= 0; i--){
            mScrollListeners.get(i).onScrollStateChanged(this, state);
        }
    }
}
```

`dispatchOnScrollStateChanged`中的所有listener默认都是空实现， `mLayout.onScrollStateChanged`只有`StaggeredGridLayoutManager`进行了一个非空实现

## 点击事件处理

```java
public boolean onTouchEvent(MotionEvent e){
    if(mLayoutSuppressed || mIgnoreMotionEventTillDown){
        return false;
    }
    if(dispatchToOnItemTouchListeners(e)){
        cancelScroll();
    }
    if(mLayout == null){
    	return false;
    }
    final boolean canScrollHorizontally = mLayout.canScrollHorizontally();
    final boolean canScrollVertically = mLayout.canScrollVertically();
    
    if(mVelocityTracker == null){
        mVelocityTracker = VelocityTracker.obtain();
    }
    boolean eventAddedToVelocityTracker = false;
    
    final int action = e.getActionMasked();
    final int actionIndex = e.getActionIndex();
    if(action == MotionEvent.ACTION_DOWN){
        mNestedOffsets[0] = mNestedOffsets[1] = 0;
    }
    final MotionEvent vtev = MotionEvent.obtain(e);
    vetv.offsetLocation(mNestedOffsets[0], mNestedOffsets[1]);
    
    switch(action){
        case MotionEvent.ACTION_DOWN:{
            mScrollPointerId = e.getPointerId(0);
            mInitialTouchX = mLastTouchX = (int)(e.getX() + 0.5f);
            mInitialTouchY = mLastTouchY = (int)(e.getY() + 0.5f);
            
            int nestedScrollAxis = ViewCompat.SCROLL_AXIS_NONE;
            if(canScrollHorizontally){
                nestedScrollAxis |= ViewCompat.SCROLL_AXIS_HORIZONTAL;
            }
            if(canScrollVertically){
                nestedScrollAxis |= ViewCompat.SCROLL_AXIS_VERTICAL;
            }
            startNestedScroll(nestedScrollAxis, TYPE_TOUCH);
        }break;
        case MotionEvent.ACTION_POINTER_DOWN:{
            mScrollPointerId = e.getPointerId(actionIndex);
            mInitialTouchX = mLastTouchX = (int)(e.getX(actionIndex) + 0.5f);
            mInitialTouchY = mLastTouchY = (int)(e.getY(actionIndex) + 0.5f);
            
        }break;
        case MotionEvent.ACTION_MOVE:{
            final int index = e.getPointerIndex(mScrollPointerId);
            if(index < 0){
                Log.e(TAG, "Error processing scroll; pointer index for id " + mScrollPointerId + " not found. Did any MotionEvents get skipped?");
                return false;
            }
            final int x = (int)(e.getX(index) + 0.5f);
            final int y = (int)(e.getY(index) + 0.5f);
            int dx = mLastTouchX - x;
            int dy = mLastTouchY - y;
            if(mScrollState != SCROLL_STATE_DRAGGING){
                boolean startScroll = false;
                if(canScrollHorizontally){
                    if(dx > 0){
                        dx = Math.max(0, dx - mTouchSlop);
                    }else{
                        dx = Math.min(0，dx + mTouchSlop);
                    }
                    if(dx != 0){
                        startScroll = true;
                    }
                }
                if(canScrollVertically){
                    if(dy > 0){
                        dy = Math.max(0, dy - mTouchSlop);
                    }else{
                        dy = Math.min(0, dy + mTouchSlop);
                    }
                    if(dy != 0){
                        startScroll = true;
                    }
                }
                if(startScroll){
                    setScrollState(SCROLL_STATE_DRAGGING);
                }
            }
            if(mScrollState == SCROLL_STATE_DRAGGING){
                mReusableIntPair[0] = 0;
                mReusableIntpair[1] = 0;
                if(dispatchNestedPreScroll(
                    canScrollHorizontally? dx: 0,
                    canScrollVertical ? dy: 0,
                    mReusableIntPair, mScrollOffset, TYPE_TOUCH
                )){
                    dx -= mReusableIntPair[0];
                    dy -= mReusableIntPair[1];
                    
                    mNestedOffsets[0] += mScrollOffset[0];
                    mNestedOffsets[1] += mScrollOffset[1];
                    
                    getParent().requestDisallowInterceptTouchEvent(true);
                }
                mLastTouchX = x - mScrollOffset[0];
                mLastTouchY = y - mScrollOffset[1];
                //核心， 用这个方法去进行滑动。
                if(scrollByInternal(
                	canScrollHorizontally? dx: 0,
                    canScrollVertically? dy: 0,
                    e
                )){
                    getParent().requestDisallowInterceptTouchEvent(true);
                }
                if(mGapWorker != null && (dx != 0 || dy != 0)){
                    mGapWorker.postFromTraversal(this, dx, dy);
                }   
            }
        }break;
    }
    
}
```



