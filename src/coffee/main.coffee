angular = require 'angular'
ngRoute = require 'angular-route'
ngSanitize = require 'angular-sanitize'

module = angular.module 'app', ['ngRoute', 'ngSanitize']

module.directive 'translator', () ->
  directive = {}

  directive.restrict = 'E'

  directive.template = "<audio hidden controls src=''></audio>"

  directive.link = (scope, elem, attrs) ->
      scope.readOnly = false;

      play = ->
        audio = elem[0].children[0];
        if scope.player.notifyStr != ""
          audio.src = "/translate/" + scope.player.notifyStr
          scope.player.notifyStr = ""
        else
          audio.src = "/translate/" + scope.player.currentNum

        console.log("playing from source " + audio.src)
        audio.load()
        audio.play()
        
      scope.$watch "player.trigger", play
  
  directive


mainController = ($scope, $sce) ->

  lang = "fi"

  $scope.correctNums = []
  $scope.incorrectNums = []

  newNum = ->
    num = Math.floor(Math.random() * 100) + 1
    included = num in $scope.correctNums
    if included 
      newNum() 
    else 
      num


  $scope.player = { trigger: 0,  currentNum: newNum(), notifyStr: "" }

  $scope.nums = [1..100]

  play = ->
    $scope.player.trigger = $scope.player.trigger + 1

  $scope.playCurrent = ->
    play()

  $scope.checkAnswer = (num) ->
    if num == $scope.player.currentNum
      console.log("correct")
      $scope.correctNums.push(num)
      $scope.incorrectNums = []
      $scope.player.currentNum = newNum()
      play()      
    else 
      console.log(num + " is incorrect " + $scope.player.currentNum)
      $scope.incorrectNums.push(num)
      #$scope.player.notifyStr = "Ei " + num + " vaan " + $scope.player.currentNum
      #play()


module.controller 'MainCtrl', ['$scope', '$sce', mainController]