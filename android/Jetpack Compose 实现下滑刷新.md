# 引入依赖

首先引入google提供的依赖

```groovy
    implementation 'com.google.accompanist:accompanist-swiperefresh:0.28.0'

```

# MVI 的 ViewModel状态建设

这里就用Flow来实现观察者模式

```kotlin
class SwipeRefreshViewModel: ViewModel() {
    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    init{
        loadStuff()
    }
    fun loadStuff() {
        viewModelScope.launch{
            _isLoading.value = true
            delay(3000L)
            _isLoading.value = false
        }
    }

}

```

## 前端页面

```kotlin
@OptIn(ExperimentalMaterialApi::class)
@Composable
fun SwipeRefreshTest(){
    //get the view model.
    val viewModel = ViewModelProvider(LocalContext.current as ViewModelStoreOwner)[SwipeRefreshViewModel::class.java]
    //tranverse it to state.
    val isLoading by viewModel.isLoading.collectAsState()
    //create PullRefreshState.
    val refreshState = rememberPullRefreshState(refreshing = isLoading, onRefresh = viewModel::loadStuff)
    //set the modifier to the Box.
    //in Box, set two Element, one is PullRefreshIndicator, another is the Layout you want to refresh or the RefreshLayout's component is traditional xml layout method.
    Box(modifier = Modifier.pullRefresh(refreshState, true)){
        PullRefreshIndicator(refreshing = isLoading, state = refreshState, modifier = Modifier.align(
            Alignment.TopCenter))
        LazyColumn(modifier = Modifier.fillMaxSize()){
            items(100){
                Text(text = "Test", modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp))
            }
        }
    }
}
```

其实相当简单