# cdim 

*cdim* (**cd** **imp**roved) is a small PowerShell module which add the following functionalities to the "cd" command:
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
current: D:\src\exercices\undergraduate-finance
desk: C:\Users\serge\OneDrive\Desktop
docs: C:\Users\serge\OneDrive\Documents
----------
History:
----------
....
```
