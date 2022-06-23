/*
 *  Copyright (C), 2015-2021
 *  FileName: paging_mixin
 *  Author: Tonight丶相拥
 *  Date: 2021/8/4
 *  Description: 
 **/

part of httpplugin;

mixin PagingMixin<T> {
  int page = 1;

  List<T> data = [];
  bool get hasMoreData => data.length % _pageSize == 0 || data.length == 0;
  bool get loadMoreData => data.length > 0;


  Future dataRefresh(){
    return Future.value();
  }

  Future loadMore(){
    return Future.value();
  }

  Future dataRefreshWithBool(bool pageReset){
    return Future.value();
  }
}