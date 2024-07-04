# 显示窗体

Java中，顶层窗口称之为`窗体（frame）`

```java

public class SimpleFrameTest{
    public static void main(String...args){
        EventQueue.invokeLater(() -> {
            var frame = new SimpleFrame();
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setVisible(true);
        });
    }
}
class SimpleFrame extends JFrame{
    private static final int DEFAULT_WIDTH = 300;
    private static final int DEFAULT_HEIGHT = 200;
    public SimpleFrame(){
        setSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }
}
```

默认情况下， 窗体的大小为0x0

所有的Swing组件必须由`事件分派线程(event dispatch thread)`配置， 其将鼠标点击，按键等事件传递给用户接口组件。

## 窗体属性

* `setLocation`和`setBounds`方法用于窗体设置

* `setIconImage`方法用于告诉窗口系统在标题栏，任务切换窗口等位置显示哪个图标

* `setTitle`方法用于改变标题栏的文字
* `setResizable`确定是否允许用户改变窗体的大小

# 在组件中显示信息

JFrame中，所有的添加的组件都会自动添加到`内容窗格（content pane）`中。

要在一个组件上绘制，需要定义一个`JComponent`类，并覆盖其中的`paintComponent`方法。

```java
public class NotHelloWorld{
    public static void main(String...args){
        EventQueue.invokeLater(() -> {
            var frame = new NotHelloWorldFrame();
            frame.setTitle("NotHelloWorld");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setVisible(true);
        });
    }
}

class NotHelloWorldFrame extends JFrame{
    public NotHelloWorldFrame(){
        add(new NotHelloWorldComponent());
        pack();
    }
}

/**
 * A component that displays a message.
 */
class NotHelloWorldComponent extends JComponent{
    public static final int MESSAGE_X = 75;
    public static final int MESSAGE_Y = 100;
    
    private static final int DEFAULT_WIDTH = 300;
    private static final int DEFAULT_HEIGHT = 200;
    @Override
    public void paintComponent(Graphics g){
        g.drawString("Not a Hello, World program", MESSAGE_X, MESSAGE_Y);
    }
    @Override
    public Dimension getPreferredSize() {
        return new Dimension(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }
}
```

### 处理2D图形

Java2D库针对像素采用的是浮点坐标，而不是整数坐标。

Rectangle2D和Ellipse对象很容易构造， 需要指定

* 左上角的x和y坐标
* 宽和高

构造椭圆如果只知道中心点, 则可以使用`setFrameFromCenter`方法

```java
var ellipse = 
    new Ellipse2D.Double(centerX - width / 2, centerY - height / 2, width, height);
```

构造直线需要提供起点和终点

```java
var line = new Line2D.double(start, end);
```

或

```java
var line = new Line2D.Double(startX, startY, endX, endY);
```

```java
public class DrawTest{
    public static void main(String...args){
        EventQueue.invokeLater(() -> {
            var frame = new DrawFrame();
            frame.setTitle("DrawTest");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setVisible(true);

        });
    }
}
/**
 * A frame that contains a panel with drawings.
 */
class DrawFrame extends JFrame{
    public DrawFrame(){
        add(new DrawComponent());
        pack();
    }
}
/**
 * A component that displays rectangle and ellipses. 
 */
class DrawComponent extends JComponent{
    private static final int DEFAULT_WIDTH = 400;
    private static final int DEFAULT_HEIGHT = 400;
    @Override
    protected void paintComponent(Graphics g) {
        var g2 = (Graphics2D) g;
        // draw a rectangle.
        double leftX = 100;
        double topY = 100;
        double width = 200;
        double height = 150;
        var rect = new Rectangle2D.Double(leftX, topY, width, height);
        g2.draw(rect);

        //draw the enclosed ellipse
        var ellipse = new Ellipse2D.Double();
        ellipse.setFrame(rect);
        g2.draw(ellipse);

        //draw a diagonal line.
        g2.draw(new Line2D.Double(leftX, topY, leftX + width, topY + height));
        //draw a circle with the same center.
        double centerX = rect.getCenterX();
        double centerY = rect.getCenterY();
        double radius = 150;
        var circle = new Ellipse2D.Double();
        circle.setFrameFromCenter(centerX, centerY, centerX + radius, centerY + radius);
        g2.draw(circle);
    }
    @Override
    public Dimension getPreferredSize() {
        return new Dimension(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }
}
```

![image-20221024140258983](https://s2.loli.net/2022/10/24/QTtaVDjPpsYWb8R.png)

### 使用颜色

使用`Graphics2D`的`setPaint`方法可以为图形上下文的后续绘制操作选择颜色。

可以使用三色分量来创建`Color`对象,

```java
g2.setPaint(new Color(0, 128, 128));
g2.drawString("Welcome!", 75, 125);
```

设置背景颜色使用`Component`类的`setBackground`方法。

### 使用字体

要想知道某台特定计算机上可用的字体，可以调用`GraphicsEnvironment`的`getAvailableFontFamilyNames`方法。

```java
String[] fontNames = GraphicsEnvironment
    .getLocalGraphicsEnvironment()
    .getAvailableFontFamilyNames();
for(String fontName: fontNames){
    System.out.println(fontName);
}
```

要想指定某种字体绘制字符，必须首先创建一个`Font`类对象。需要指定字体名， 字体风格，字体大小。

```java
var sansbold14 = new Font("SansSerif", Font.BOLD, 14);
```

Font构造器的第二个参数可以设置为以下值：

* Font.PLAIN
* Font.BOLD
* Font.ITALIC
* Font.BOLD + Font.ITALIC 

第三个参数是以点数目计算的字体大小，每英寸包含72个点。
常规字体大小为1点， 可以使用`deriveFont`方法得到所需大小的字体

```java
Font f = f1.deriveFont(14.0F);
```

`deriveFont`方法传参int类型设置字体风格，float设置字体大小。

要得到表示屏幕设备字体属性的对象，需要调用`Graphics2D`的`getFontRenderContext`方法

```java
FontRenderContext context = g2.getFontRenderContext();
Rectangle2D bounds = sansbold14.getStringBounds(message, context);
```

得到一个包围字符串的矩形。

如果需要知道下坡度或行间距，可以使用Font类的`getLineMetrics`方法。这个方法将返回一个`LineMetrics`对象

```java
LineMetrics metrics = f.getLineMetrics(message, context);
float descent = metrics.getDescent();
float leading = metrics.getLeading();
```



```java

public class FontTest{
    public static void main(String...args){
        EventQueue.invokeLater(() -> {
            var frame = new FontFrame();
            frame.setTitle("FontTest");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setVisible(true);
        });
    }
}
/**
 * A frame with a text message component.
 */
class FontFrame extends JFrame{
    public FontFrame(){
        add(new FontComponent());
        pack();
    }
}

/**
 * A componenent that shows a centered message in a box.
 */
class FontComponent extends JComponent{
    private static final int DEFAULT_WIDTH = 300;
    private static final int DEFAULT_HEIGHT = 200;

    @Override
    protected void paintComponent(Graphics g) {
        var g2 = (Graphics2D) g;
        var message = "Hello, World!";
        var f = new Font("Serif", Font.BOLD, 36);
        g2.setFont(f);
        //measure the size of the message
        FontRenderContext context = g2.getFontRenderContext();
        Rectangle2D bounds = f.getStringBounds(message, context);
        double x = (getWidth() - bounds.getWidth()) / 2;
        double y = (getHeight() - bounds.getHeight()) / 2;
        //add ascent to y to reach the baseline.
        double ascent = -bounds.getY();
        double baseY = y + ascent;

        //fraw the message.
        g2.drawString(message, (int)x, (int)baseY);
        g2.setPaint(Color.LIGHT_GRAY);

        g2.draw(new Line2D.Double(x, baseY, x + bounds.getWidth(), baseY));
        var rect = new Rectangle2D.Double(x, y, bounds.getWidth(), bounds.getHeight());
        g2.draw(rect);
 
    }
    @Override
    public Dimension getPreferredSize() {
        return new Dimension(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    }
}
```

![image-20221024143723284](https://s2.loli.net/2022/10/24/si9AldQ4eS2w1kY.png)

### 显示图像

可以使用`ImageIcon`类从文件读取图像

```java
Image image = new ImageIcon(fileName).getImage();
```

可以使用`Graphics`类的`drawImage`方法显示这个图像

```java
public void paintComponent(Graphics g){
    ...
    g.drawImage(image, x, y, null);
}
```

# 事件处理

## 处理按钮点击事件

想要创建一个按钮，要在按钮构造器中指定一个标签字符串或一个图标， 或者两项都指定

```java
var yellowButton = new JButton("Yellow");
var blueButton = new JButton(new ImageIcon("blue-ball.gif"));
```

调用`add`方法将按钮添加到面板中

```java
var yellowButton = new JButton("Yellow");
var blueButton = new JButton("Blue");
var redButton = new JButton("Red");

buttonPanel.add(yellowButton);
buttonPanel.add(blueButton);
buttonPanel.add(redButton);
```

```java
public class ButtonFrame extends JFrame{
    private JPanel buttonPanel;
    private static final int DEFAULT_WIDTH = 300;
    private static final int DEFAULT_HEIGHT = 200;
    public ButtonFrame(){
        setSize(new Dimension(DEFAULT_WIDTH, DEFAULT_HEIGHT));

        //create buttons
        var yellowButton = new JButton("Yellow");
        var blueButton = new JButton("blue");
        var redButton = new JButton("Red");

        buttonPanel = new JPanel();

        buttonPanel.add(yellowButton);
        buttonPanel.add(blueButton);
        buttonPanel.add(redButton);
        //add panel to frame;
        add(buttonPanel);

        var yellowAction = new ColorAction(Color.YELLOW);
        var blueAction = new ColorAction(Color.BLUE);
        var redAction = new ColorAction(Color.RED);
        yellowButton.addActionListener(yellowAction);
        blueButton.addActionListener(blueAction);
        redButton.addActionListener(redAction);
    }
    private class ColorAction implements ActionListener{
        private Color backgroundColor;
        public ColorAction(Color c){
            backgroundColor = c;
        }
        @Override
        public void actionPerformed(ActionEvent e) {
            buttonPanel.setBackground(backgroundColor);
        }
    }
}

```

![image-20221024163144130](https://s2.loli.net/2022/10/24/5YQiyo4vb7hm13u.png)

## 适配器类

当程序试图关闭一个窗口时，`JFrame对象`就是`WindowEvent`的事件源，如果希望捕获这个事件，就必须有一个合适的监听器对象。

```java
WundowListener listener = ...;
frame.addWindowListener(listener);
```

`WindowListener`包含7个方法，窗体将调用这些方法响应7个不同的窗体事件。

```java
public interface WindowListener{
    void windowOpened(WindowEvent e);
    void windowClosing(WindowEvent e);
    void windowClosed(WindowEvent e);
    void windowIconified(WindowEvent e);
    void windowDeiconified(WindowEvent e);
    void windowActivated(WindowEvent e);
    void windowDeactivated(WindowEvent e);
}
```

`WindowAdapter`是一个拥有这些所有方法空实现的一个适配器类。

可以扩展适配器类来指定某些动作的响应，而不必实现接口中的每一个方法。

```java
ckass Terminator extends WindowAdapter{
    @Override
    public void windClosing(WindowEvent e){
        if(user agrees)
            System.exit(0);
    }
}
```

### 动作

`Action`接口包含如下方法

```java
public interface Action{
    void actionPerformed(ActionEvent event);
    void setEnabled(boolean b);
    boolean isEnabled();
    void putValue(String key, Object value);
    Object getValue(String key);
    void addPropertyChangeListener(PropertyChangeListener listener);
    void removePropertyChangeListener(PropertyChangeListener listener);
}
```

`putValue`和`getValue`方法有两个重要的预定义字符串： Action.NAME 和 Action.SMALL_ICON， 用于将动作的名字和图标存储到一个动作数组中。

Action接口的最后两个方法能够让其他对象在动作对象发生变化时得到通知。

```java
public class ColorAction extends AbstractAction
{
    public ColorAction(String name, Icon icon, Color c){
        putValue(Action.NAME, name);
        putValue(Action.SMALL_ICON, icon);
        putValue("color", c);
        putValue(Action.SHORT_DESCRIPTION, "Set panel color to " + name.toLowerCase());
    }
    public actionPerformed(ActionEvent e){
        Color c = (Color) getValue("color");
        buttonPanel.setBackground(c);
    }
}
```

为了将动作对象添加到按键，需要生成`KeyStroke`对象。

```java
KeyStroke ctrlBKey = KeyStroke.getKeyStroke("ctrl B");
```

每个`JComponent`有三个**输入映射（input map）**，分别将`KeyStroke`对象映射到关联的动作

| 标志                               | 激活动作                                             |
| ---------------------------------- | ---------------------------------------------------- |
| WHEN_FOCUSED                       | 当这个组件拥有键盘焦点时                             |
| WHEN_ANCESTOR_OF_FOCUSED_COMPONENT | 当这个组件包含拥有键盘焦点的组件时                   |
| WHEN_IN_FOCUSED_WINDOW             | 当这个组件包含在拥有键盘焦点的组件所在的同一个窗口时 |

按键处理将按照如下顺序

1. 检查WHEN_FOCUSED映射，若有则拦截动作，停止处理
2. 检查父部件的WHEN_ANCESTOR_OF_FOCUSED_COMPONENT映射。
3. 查看所有**可见**和**已启动**的组件是否有WHEN_IN_FOCUSED_WINDOW映射动作。

可以使用`getInputMap`方法从组件中得到输入映射

```java
InputMap imap = panel.getInputMap(JComponent.WHEN_FOCUSED);
```

`InputMap`不是将`KeyStroke`对象映射到`Action`对象, 而是先映射到任意对象，然后由`ActionMap`类实现的第二个映射将动作映射到动作。

```java
imap.put(KeyStroke.getKeyStroke("ctrl Y"), "panel.yellow");
ActionMap amap = panel.getActionMap();
amap.put("panel.yellow", yellowAction);
```

习惯上，使用字符串"none"表示空动作

### 鼠标事件

用户点击鼠标后，将会调用三个监听器方法

* mousePressed
* mouseReleased
* mouseClicked

要想区分单击，双击，三击， 需要使用`getClickCount`方法

如果用户在移动鼠标的同时按下鼠标，就会生成`mouseDragged`调用而不是`mouseMoved`调用

# 首选项API

Preference类以一种平台无关的方式提供了一个存储配置信息的中心存储库。

在Windows中使用注册表来保存信息，Linux上存储在本地文件系统中。

Preference存储库为树状结构， 节点路径名通常类似于包名。

存储库的各个节点分别有一个单独的键/值对表。

若要访问一个节点， 需要先从用户或系统根开始：

```java
Preferences root = Preferences.userRoot();
//or
Preferences root = Preferences.systemRoot();
```

访问节点可以提供一个节点路径名

```java
PReferences node = root.node("/com/saigyouji/java_series");
```

如果节点路径名等于类的包名， 可以如此调用

```java
Preferences node = Preferences.userNodeForPackage(obj.getClass());
//or
Preferences node = Preferences.systemNodeForPackage(obj.getClass());
```

类似Windows注册表的中心存储库通常存在两个问题：

* 容易变成充斥着过期信息的"垃圾场"
* 配置文件和数据库纠缠在一起， 很难把首选项迁移到新平台

对于第二个问题，可以通过如下方法导出一个子树

```java
void exportSubtree(OutputStream out);
void exportNode(OutputStream out);
```

使用以下方法将数据导出

```java
void importPreferences(InputStream in)
```

```java
public class ImageViewer {
    public static void main(String[] args) {
        EventQueue.invokeLater(() -> {
            var frame = new ImageViewerFrame();
            frame.setTitle("ImageViewer");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.setVisible(true);

        });
    }
}

/**
 * An image viewer that restores position, size, and image from user
 * preferences and updartes the preferences upon exit.
 */
class ImageViewerFrame extends JFrame{
    private static final int DEFAULT_WIdTH = 300;
    private static final int DEFAULT_HEIGHT = 200;
    private String image;
    public ImageViewerFrame(){
        Preferences root = Preferences.userRoot();
        Preferences node = root.node("/com/saigyouji/java_series/ImageViewer");
        //get position, size, title from properties.
        int left = node.getInt("left", 0);
        int top = node.getInt("top", 0);
        int width = node.getInt("width", 0);
        int height = node.getInt("height", 0);
        setBounds(left, top, width, height);
        image = node.get("image", null);
        var label = new JLabel();
        if(image != null) label.setIcon(new ImageIcon(image));
        addWindowListener(new WindowAdapter(){
            @Override
            public void windowClosing(WindowEvent e) {
                node.putInt("left", getX());
                node.putInt("top", getY());
                node.putInt("width", getWidth());
                node.putInt("height", getHeight());
                node.put("image", image);
            }
        });
        //use a label to display the images
        add(label);
        //set up the file chooser
        var chooser = new JFileChooser();
        chooser.setCurrentDirectory(new File("."));

        //setup the menu bar.
        var menuBar = new JMenuBar();
        setJMenuBar(menuBar);

        var menu = new JMenu("File");
        menuBar.add(menu);

        var openItem = new JMenuItem("Open");
        menu.add(openItem);
        openItem.addActionListener(event -> {
            //show file chooser dialog.
            int result = chooser.showOpenDialog(null);
            //if file selected, set it as icon of the label.
            if(result == JFileChooser.APPROVE_OPTION){
                image = chooser.getSelectedFile().getPath();
                label.setIcon(new ImageIcon(image));
            }
        });
        var exitItem = new JMenuItem("Exit");
        menu.add(exitItem);
        exitItem.addActionListener(event -> {
            System.exit(0);
        });
    }
}
```

![image-20221024195736131](https://s2.loli.net/2022/10/24/ZYqh4IXzESr6my3.png)

