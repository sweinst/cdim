# cdim 

*cdim* (**cd** **imp**roved) is a small *PowerShell Core* module which add the following functionalities to the "cd" command:
- bookmarks (persisted)
- automatic directory navigation history (only for the current session)

## bokmarks
- To add a bookmark: navigate to the directory and run:
```powershell
> cd -b bookamrk_name
```
- To remove a bookmark: run:
```powershell
> cd -d bookamrk_name
```
- To navigate to a bookmark: run:
```powershell
> cd %bookamrk_name
```
- To list all bookmarks:
```powershell
> cd -l
----------
Bookmarks:
----------
3d: D:\src\3d
books: Microsoft.PowerShell.Core\FileSystem::\\serge_linux\library
desk: C:\Users\serge\OneDrive\Desktop
docs: C:\Users\serge\OneDrive\Documents
----------
History:
----------
....
```

## Navigation history
A list of the 10 last visited directories is maintained
- To list all the navigation history:
```powershell
> cd -l
----------
Bookmarks:
----------
....
----------
History:
----------
1: /etc/samba
2: /var/log
3: /opt
```
- To navigate to a directory in the history:
```powershell
> cd %3
```
For the previous visited directory, just run:
```powershell
> cd -
```
