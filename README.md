# MX-command-system

## 介绍
插入本脚本可以让其具有斜杠命令功能。例如：
```
/attr set CUR_XP 0 XXXXX
```
(将XXXXX的当前生命值改为0）

**内置命令**

有许多内置命令，例如```chat```、```tp```等

**高自定义性**

可以方便的自定义命令，只需要给数组赋值即可。例如：
```
lcmds["tphost"] = {}
lcmds["tphost"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    --判断参数个数
    print(e)
    if not (getTableLength(e.args) == 0) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    else
        local ret, x, y, z = Actor:getPosition(hostUin)
        if (ret == ErrorCode.FAILED) then
            return Err.codeError
        end
        sysMsg("你将被传送到x:" .. x .. ",y:" .. y .. ",z:" .. z, e.uin)
        Player:setPosition(e.uin, x, y, z)
    end
end
```

## 致谢
（暂时还没有）