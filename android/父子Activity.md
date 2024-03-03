# 父子Activity

在AndroidManifest.xml的activity块中可以声明parentActivityName

则AppBar中自动生成回退键

手动实现:

```kotlin
supportActionBar?.setDisplayhomeAsUpEnabled(true)
supportActionBar?.setHomeAsUpIndicator(R.drawable.ic_back)

override fun onOptionsItenSelected(item: MenuItem): Boolean{
    if(item.itemId == android.R.id.home){
        finish()
    }
    return super.onOptionsItemSelected(item)
}
```

清空堆栈方法

```kotlin
fun exitApp(context: Context){
    finishAllActiviy()
    val activityManager = context.getSystemService(
        Context.ACTIVITY_SERVICE
    ) as ActivityManager
    activityManager.killBackgroundProcesses(context.packageName)
    exitProcess(0)
}
```

## 多入口Activity

AndroidManifest当软件启动时， 扫到的第一个默认启动页面的intentFilter将作为默认的启动Activity。

android:exported 告诉系统该Activity是否可以由外界启动