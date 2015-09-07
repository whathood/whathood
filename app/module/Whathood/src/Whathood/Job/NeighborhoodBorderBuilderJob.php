<?php

namespace Whathood\Job;


use Whathood\Entity\NeighborhoodPolygon;
use SlmQueue\Job\AbstractJob;
use Whathood\Timer;
use Whathood\Election\PointElectionCollection;
use Whathood\Entity\Neighborhood;

class NeighborhoodBorderBuilderJob extends \Whathood\Job\AbstractJob
{

    protected $_gridResolution;
    protected $_mapperBuilder;

    public function setGridResolution($gridResolution) {
        $this->_grid_resolution = $gridResolution;
    }

    public function __construct(array $data) {
        parent::__construct($data);
    }

    public function getNeighborhood() {
        return $this->getContent()['neighborhood'];
    }

    public function getUserPolygons() {
        return $this->getContent()['userPolygons'];
    }

    public function execute() {
        $api_timer = Timer::start('api');

        $this->logger()->info("grid-resolution: ".rtrim(sprintf("%.8F",$this->getGridResolution()),"0"));

        $neighborhood = $this->getNeighborhood();
        $userPolygons = $this->getUserPolygons();
        $this->logFoundUserBorders($userPolygons);

        $this->logger()->info(
            sprintf("\tprocessing id=%s name=%s num_user_polygons=%s",
                $neighborhood->getId(),
                $neighborhood->getName(),
                count($userPolygons)
                )
        );
        try {
            /* build the border */
            $timer = Timer::start('generate_border');
            $electionCollection = $this->m()->pointElectionMapper()->getCollection(
                $ups,
                $n->getId(),
                $this->getGridResolution()
            );

            if (empty($electionCollection->getPointElections())) {
               $this->logger()->warn("electionCollection contains no points");
            }
            else {
                try {
                    if ($this->buildAndSaveNeighborhoodPolygon($electionCollection, $n, $ups)) {
                        $this->logger()->info(
                            sprintf("\t\tsaved neighborhood polygon elapsed=%s", $timer->elapsedReadableString()));

                        $this->buildAndSaveHeatmapPoints($ups, $n, $this->getHeatmapGridResolution());
                    }
                    else {
                        $this->logger()->err("did not get a neighborhood polygon");
                    }
                }
                catch(\Whathood\Exception $e) {
                    $this->logger()->err("Failed to build polygon for ".$n->getName().": ". $e->getMessage());
                } catch(\Exception $e) {
                    $this->logger()->err("big error trying to build neighborhood polygon");
                    $this->logger()->err(get_class($e));
                    $this->logger()->err($e);
                }
            }
            $timer->stop();
        }
        catch(\Exception $e) {
            $this->logger()->err($e->getMessage());
            $this->logger()->err($e->getTraceAsString());
            $err_msg = "FATAL: the watcher script died because of an error\n";
            $this->logger()->err($err_msg);
            die($err_msg);
        }
        $this->logger()->debug("job finished");
    }

    public function m() {
        return $this->_mapperBuilder;
    }

    public function logFoundUserBorders($user_polygons) {
        foreach($user_polygons as $up) {
            $this->logger()->debug(
                sprintf("\tfound new user generated polygon(%s) for neighborhood %s",
                    $up->getId(),
                    $up->getNeighborhood()->getName()
                )
            );
        }
    }

    public function buildAndSaveNeighborhoodPolygon(PointElectionCollection $electionCollection, Neighborhood $n,$ups) {
        $polygon = $this->m()->pointElectionMapper()->generateBorderPolygon(
            $electionCollection, $n
        );

        if (!$polygon) {
            $this->logger()->warn("Could not construct a neighborhood border for ".$n->getName());
            return;
        }

        $neighborhoodPolygon = NeighborhoodPolygon::build( array(
            'geom' => $polygon,
            'neighborhood' => $n,
            'user_polygons' => $ups,
            'grid_resolution' => $this->getGridResolution()
        ));
        $this->m()->neighborhoodPolygonMapper()->save($neighborhoodPolygon);
        $this->m()->neighborhoodPolygonMapper()->detach($neighborhoodPolygon);
        return $neighborhoodPolygon;
    }

    /**
     * take the user polygons, run a point election, and save the points in the db
     **/
    public function buildAndSaveHeatmapPoints($user_polygons, Neighborhood $n, $grid_resolution) {

        $timer = Timer::start("heatmap_builder");
        $electionCollection = $this->m()->pointElectionMapper()
            ->getCollection(
                $user_polygons,
                $n->getId(),
                $grid_resolution
            );

        $heatmap_points = $electionCollection->heatMapPointsByNeighborhood($n);

        if (!empty($heatmap_points)) {
            $this->m()->heatMapPoint()->deleteByNeighborhood($n);
            $this->m()->heatMapPoint()->savePoints($heatmap_points);
            $this->m()->heatMapPoint()->detach($heatmap_points);
            $this->logger()->info(
                sprintf("\t\tsaved %s heatmap points from %s points elapsed=%s",
                    count($heatmap_points), count($electionCollection->getPointElections()), $timer->elapsedReadableString()
                )
            );
        }
        else
            $this->logger()->info("\t\tno heatmap_points generated to save");
        return $heatmap_points;
    }
}
