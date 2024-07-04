@[TOC](StartActivityForResult的替代方案)

# StartActivityForResult方法被弃用的替代方案

使用registerForActivityResult进行替代， 亲测可用

首先创建一个Contract Class implements ActivityResultContract<X, Y>, 重写 creatIntent， parseResult

X， Y 分别指传入参数和传出参数

```java
class Contract extends ActivityResultContract<Integer, String>
    {
        @NonNull
        @Override
        public Intent createIntent(@NonNull Context context, Integer input)
        {
            var intent = new Intent(context, NewWordActivity.class);
            return intent;
        }
        @Override
        public String parseResult(int resultCode, @Nullable Intent intent)
        {
            if(resultCode == RESULT_OK) {
                Word word = new Word(intent.getStringExtra(NewWordActivity.EXTRA_REPLY));
                mWordViewModel.insert(word);
                return intent.getStringExtra(NewWordActivity.EXTRA_REPLY);
            }
            else
                return "";
        }
    }
```

创建活动启动器

```java'
var launcher = registerForActivityResult(new Contract(), new ActivityResultCallback<String>()
        {
            @Override
            public void onActivityResult(String result)
            {
                if(result.equals(""))
                    Toast.makeText(getApplicationContext(), R.string.empty_not_saves, Toast.LENGTH_LONG).show();
            }
        });
```

使用时启动即可

```java
fab.setOnClickListener(v ->
        {
             launcher.launch(NEW_WORD_ACTIVITY_REQUEST_CODE);
        });
    }
```

