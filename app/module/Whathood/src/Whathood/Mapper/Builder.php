<?php
namespace Whathood\Mapper;

class Builder extends BaseMapper {

    protected $sm;
    protected $_entityManager;

    protected $neighborhoodPolygonMapper;
    protected $neighborhoodMapper;
    protected $regionMapper;
    protected $whathoodUserMapper;
    protected $_spatial_platform;
    protected $_user_polygon_mapper;
    protected $_test_point_mapper;
    protected $_points_as_polygon_mapper;
    protected $_heatmap_point;
    protected $_queue_mapper;
    protected $_neighborhood_boundary;

    public function __construct( $serviceManager, $doctrineEntityManager ) {
        if( !($serviceManager instanceof \Zend\ServiceManager\ServiceManager) )
            throw new \InvalidArgumentException(
                                    "serviceManager must be of type dfafdaf");
        $this->sm = $serviceManager;
        $this->_entityManager = $doctrineEntityManager;
    }

    public function entityManager() {
        return $this->_entityManager;
    }

    public function postgresMapper() {
        return $this->sm->get('Whathood\Mapper\PostgresMapper');
    }

    public function stSimplifyMapper() {
        return $this->sm->get('Whathood\Mapper\StSimplifyMapper');
    }

    public function pointElectionMapper() {
        return $this->sm->get('Whathood\Mapper\PointElectionMapper');
    }

    public function neighborhoodBoundaryMapper() {
        if ($this->_neighborhood_boundary == null) {
            $this->_neighborhood_boundary = $this->sm->get('Whathood\Mapper\NeighborhoodBoundaryMapper');
        }
        return $this->_neighborhood_boundary;
    }

    public function heatMapPoint() {
        if ($this->_heatmap_point == null) {
            $this->_heatmap_point =
                $this->sm->get('Whathood\Mapper\HeatMapPoint');
        }
        return $this->_heatmap_point;
    }

    public function queueMapper() {
        if (!$this->_queue_mapper)
            $this->_queue_mapper = $this->sm->get('Whathood\Mapper\QueueMapper');
        return $this->_queue_mapper;
    }

    public function pointsAsPolygonMapper() {
        if( $this->_points_as_polygon_mapper == null )
            $this->_points_as_polygon_mapper =
                $this->sm->get('Whathood\Mapper\PointsAsPolygonMapper');
        return $this->_points_as_polygon_mapper;
    }

    public function testPointMapper() {
        if( $this->_test_point_mapper == null )
            $this->_test_point_mapper =
                $this->sm->get('Whathood\Mapper\TestPointMapper');
        return $this->_test_point_mapper;
    }
    public function userPolygonMapper() {
        if( $this->_user_polygon_mapper == null )
            $this->_user_polygon_mapper =
                $this->sm->get('Whathood\Mapper\UserPolygonMapper');
        return $this->_user_polygon_mapper;
    }

    public function neighborhoodPolygonMapper() {
        if( $this->neighborhoodPolygonMapper == null )
            $this->neighborhoodPolygonMapper =
                $this->sm->get('Whathood\Mapper\NeighborhoodBoundaryMapper');
        return $this->neighborhoodPolygonMapper;
    }

    // sugar
    public function neighborhood() {
        return $this->neighborhoodMapper();
    }

    public function neighborhoodMapper() {
        if( $this->neighborhoodMapper == null )
            $this->neighborhoodMapper =
                $this->sm->get('Whathood\Mapper\NeighborhoodMapper');
        return $this->neighborhoodMapper;
    }

    public function regionMapper() {
        if( $this->regionMapper == null )
            $this->regionMapper = $this->sm->get('Whathood\Mapper\RegionMapper');
        return $this->regionMapper;
    }

    public function whathoodUserMapper() {
        if( $this->whathoodUserMapper == null )
            $this->whathoodUserMapper = $this->sm->get('Whathood\Mapper\WhathoodUserMapper');
        return $this->whathoodUserMapper;
    }
}
?>
