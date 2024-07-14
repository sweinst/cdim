# cdim 

*cdim* (**cd** **imp**roved) is a small *PowerShell Core* module which add the following functionalities to the "cd" command:
- bookmarks (persisted)
- automatic directory navigation history (only for the current session)

## Bookmarks
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
To navigate to a directory in the history looking for a substring or a regular expression (fuzzy navigation):
```powershell
> cd my-First-dir
> cd my-Second-dir
> cd my-Thrid-dir
# will cd to  my-first-dir
> cd -f first
# will cd to  my-second-dir
> cd -f sec.*d
```

## Installation
The module is available in the PowerShell Gallery

For all users:
```powershell
> Install-Module cdim -Scope AllUsers
```
For the current user:
```powershell
> Install-Module cdim -Scope CurrentUser

```
Then run:
```powershell
> Import-Module cdim

```

If you want to enable it all the time, edit your PowerShell profile:
```powershell
# replace notepad with your favorite editor and create the file if it doesn't exist
> notepad $profile

```
Add:
```powershell
Import-Module cdim

```
at the top of it. It must be imported before any customization of PSReadLine otherwise these customizations will be lost


## Remarks
- It has been tested on Windows and Linux

- Tab completion is provided:
  - if it starts with a '%', it will try to complete it with a full bookmark name
  - otherwuise, it will try to complete with a directory name

- Personally, I prefer the "bash style" edit mode. To set it, add to your profile:
```powershell
Set-PSReadlineOption -EditMode Emacs

```
When using completion, instead of going one possible completion at a time, it displays all the possible completions:
```powershell
> cd %[TAB,TAB]

%3d            %books         %dwl           %pcurrent      %test         %scratch       %videos
%aargh         %current       %fd            %proj1         %prj2         %src           %wpf
%bh            %downloads     %informatique  %pyfi          %scoop        %vcpkg
```
