--[[ 
  Auteur : Artille
  version : 1.0.3
    
  TODO : Ajouter d'autres format de sauvegarde et chargement
  Pour l'instant, cette version ne permet de sauvegarder et charger que des tableaux à une dimension (des listes quoi)
  N'hésitez pas à l'améliorer et le partager si vous le faites
    
]]--

-- Fonctions save :
function SaveData(data)
  
  -- Fonction pour sérialiser les données du tableau
  local function serialize(tbl)
    local str = "{"
    local isFirst = true
    for key, value in pairs(tbl) do
      if not isFirst then
        str = str .. ","
      end
      if type(key) == "string" then
        str = str .. '["' .. key .. '"]='
      else
        str = str .. "[" .. tostring(key) .. "]="
      end
      if type(value) == "table" then
        str = str .. serialize(value)
      elseif type(value) == "string" then
        str = str .. '"' .. value .. '"'
      else
        str = str .. tostring(value)
      end
      isFirst = false
    end
    return str .. "}"
  end

  -- Variable complexe pour stocker les valeur du tableau provenant de l'argument de la fonction SaveData
  local dataList = {}
  
  --Lister les éléments du tableau à sauvegarder :
  for key, value in pairs(data) do
    table.insert(dataList, {key = key, value = value})
  end
  
  -- Sauvegarde dans le dossier racine du workenvironnement de Love (AppData/Roaming/LOVE/) (Remplacer "Projet" par le nom de votre projet)
  love.filesystem.setIdentity("Projet")
  -- Choisir un dossier à l'intérieur de votre projet (Commenter pour désactiver)
  love.filesystem.createDirectory("save")
  -- Choisir un nom de fichier (ajouter le dossier si vous avez choisit d'en ajouter un)
  local filename = "save/data.txt"
  
  -- On serialise le tableau dataList pour pouvoir l'encoder au format string / à noter que le format data fonctionne également
  local serializedDataList = serialize(dataList)
  -- On encode les données en base64
  local encodedData = love.data.encode( "string", "base64", serializedDataList)
  local success, errorMessage = pcall(function()
  -- Sauvegarde des données
  love.filesystem.write(filename, encodedData)
  end)
  
  -- On vérifie que la sauvegarde a bien fonctionné
  if success then
    -- TODO : ajouter une animation ou un message comme quoi la sauvegarde à fonctionné
    --print("Ecriture réussi")
  else
    print("Erreur lors de l'écriture :", errorMessage)
    return
  end
  
  
end

--[[
  
  Exemple d'utilisation dans le fichier principal :
  save = {}
  save.data = "Ceci est une chaine de caractère"
  save.data2 = "Cette variable contient le nom du joueur"
  save.data3 = 15 

  SaveData(nomDuTableau) -- Dans l'exemple ça donne SaveData(save)
  
]]--


  -- Fonction load au format : variable = fonction()
function LoadData()
  local serializedLoadData
  
  -- Si le fichier existe :
  if love.filesystem.getInfo("save/data.txt") then
    -- On lis les données
    local success, errorMessage = pcall(function()
      love.filesystem.read("save/data.txt")
    end)
    
    -- On vérifie que le chargement a bien fonctionné
    if success then
      --print("Chargement réussi")
      serializedLoadData = love.filesystem.read("save/data.txt")
    else
      print("Erreur lors du chargement :", errorMessage)
      return
    end

    -- On décode les données au format base64 pour les convertir au format string
    local loadData = love.data.decode("string", "base64", serializedLoadData)
    -- On vérifier que loadData n'est pas vide : 
    if loadData == nil then
      print("Chargement échoué, le fichier est vide")
      
      -- Si le fichier est vide, on renvoi nil
      return nil
    else 
      -- Si le fichier contient quelque chose, on transforme le contenue pour en créer une table et on renvoi son contenu
      loadedData = RecreateTableFromData(loadData)
      return loadedData
    end
    
  else
    -- Si le fichier n'existe pas on renvoi simplemen nil  
    print("Chargement échoué, le fichier n'existe pas!")
    
    -- Si le fichier est vide, on renvoi nil
    return nil
  end

end

--[[

  Exemple d'utilisation dans le fichier principal : 
  
  -- On appelle la fonction load et on récupère les valeurs sauvegardés s'il y en avait une, ensuite on stock les valeur dans loadData pour extraction : 
  loadData = LoadData()
  
  Vous pourrez ensuite récupèrer les données en suivant la même structure que les données enregistré : 
  loadData.data = "Ceci est une chaine de caractère"
  loadData.data2 = "Cette variable contient le nom du joueur"
  loadData.data3 = 15 
  
  Attention tout de même de conditionner les appels
  Si aucun fichier n'a été chargé, appeler loadData.data renverra une erreur
  
  Vous pouvez utiliser la fonction GetLoadDataValue(key) pour sécuriser l'appel, par exemple :
  local dataValue = GetLoadDataValue("data") 
  dataValue sera = à loadData.data dans cet exemple
  Ceci évitera votre jeu de se planter si jamais vous n'avez pas de fichier de sauvegarde, ou si vous appelez la mauvaise clé.

]]--


-- Fonction pour transformer la chaine de caractère sauvegardé au format d'un tableau pour utiliser les données
function RecreateTableFromData(data)
  local recreatedTable = {}
  
  -- Convertir la chaîne de caractères en table
  local success, loadedData = pcall(loadstring, "return " .. data)
  
  -- Vérifier si la conversion a réussi
  if success and type(loadedData) == "function" then
    -- Appeler la fonction pour obtenir la table résultante
    local tableData = loadedData()
    
    -- Vérifier si la table a été renvoyée
    if type(tableData) == "table" then
      -- Copier les éléments de la table dans la nouvelle table
      for _, element in ipairs(tableData) do
        recreatedTable[element.key] = element.value
        
      end
    else
      print("Erreur : Les données chargées ne correspondent pas à une table valide")
    end
  else
    print("Erreur lors de la conversion des données en table :", loadedData)
  end
  
  return recreatedTable
end

--[[

  Cette fonction est utiliser par la fonction loadData()
  Elle sert à reconvertir les données au format d'un tableau
  Elle n'est pas à utiliser par l'utilisateur, sauf s'il en a besoin spécifiquement

]]--

-- fonction de sécurité lors d'appel de loadData()
function GetLoadDataValue(key)
  -- On vérifie qu'une valeur existe pour la variable (key) accroché à loadData
  local success, value = pcall(function()
    -- On récupère la clé (variable) de loadData
    return loadData[key]
  end)
  
  if success then
    -- Si la clé existe, on renvoi sa valeur
    -- Si la valeur est nil, on renvoi nil avec une erreur 
    if value == nil then 
      print("Erreur lors de l'accès à loadData." .. key .. " :", value)
      return nil
    else
      -- Sinon on renvoi juste sa valeur
      return value
    end
    
  else
    -- Sinon, on renvoi un message d'erreur
    print("Erreur lors de l'accès à loadData." .. key .. " :", value)
    return nil
  end
end
